#pragma once
#include <QImage>
#include <QRect>
#include <QSize>
#include <cmath>
// reMarkable Paper Pro ("ferrari"), portrait at normal zoom. See docs/paper-pro/GEOMETRY.md.
//
// The screen (and the rm-shot screenshot) is 1620 x 2160. TO CONFIRM ON THE TABLET in
// Stage 1: the screenshot size, the window size and that the window scale (DPR) is 1.
inline QSize diaryScreenSize() { return QSize(1620,2160); }
// The notebook toolbar is hidden while a request runs (inkDiary.qmd, diaryHideToolbar),
// so the whole screen is page. Only our own buttons are masked out (below).
// TO CONFIRM in Stage 1: nothing else (page number, title, zoom control) stays visible.
inline QRect diaryCaptureArea() { return QRect(QPoint(0,0),diaryScreenSize()); }
// Answers are drawn 1174 px wide, as on the reMarkable 2. The Paper Pro (229 ppi) and
// rM2 (226 ppi) have almost the same pixel density, so this keeps the same physical
// answer size (about 13 cm wide) and leaves every renderer unchanged. Centred on screen.
inline int diaryAnswerWidth() { return 1174; }
inline int diaryAnswerCenterX() { return diaryScreenSize().width()/2; }
// Height budget for plots and other fixed-size answers, also kept from the rM2.
inline int diaryAnswerMaxHeight() { return 1582; }
// The Claude button (inkDiary.qmd): 72 x 72 at the right edge, 24 px in from the side
// and 160 px up from the bottom, so it clears a toolbar moved to the bottom (112 px).
// Masked with a 12 px margin. Keep these in step with inkDiary.qmd.
inline QRect diaryButtonRect() { return QRect(1512,1916,96,96); }
// The Send button (inkDiary.qmd), 120 x 72, 16 px left of it while email drafts are pending.
inline QRect diarySendButtonRect() { return QRect(1376,1916,144,96); }
// Keep our own buttons out of the page photo, the ink search and the unchanged-page check.
inline void diaryMaskControls(QImage &screen) {
    for(const QRect &r:{diaryButtonRect(),diarySendButtonRect()})
        for(int y=r.top();y<=r.bottom()&&y<screen.height();++y)
            for(int x=r.left();x<=r.right()&&x<screen.width();++x)
                screen.setPixelColor(x,y,Qt::white);
}
// Answer images are drawn in screen pixels; the notebook inserts an image at one scene
// unit per image pixel. Resize by the measured scene units per screen pixel so the
// answer appears at its drawn size. Scales outside 0.25..4 are treated as a bad mapping.
inline QImage diaryScaleForScene(const QImage &image, double sceneUnitsPerPixel) {
    if(!(sceneUnitsPerPixel>=0.25 && sceneUnitsPerPixel<=4)) return QImage();
    if(std::abs(sceneUnitsPerPixel-1.0)<0.005) return image;
    const int w=qMax(1,qRound(image.width()*sceneUnitsPerPixel)), h=qMax(1,qRound(image.height()*sceneUnitsPerPixel));
    return image.scaled(w,h,Qt::IgnoreAspectRatio,Qt::SmoothTransformation);
}
#include <array>
#include <vector>
#include <algorithm>
// A pale, nearly uniform full-width/height line is a template rule.
// Keep darker strokes on that line, and never filter black rules/content.
inline int ruleThreshold(const std::array<int,256> &histogram, int length) {
    int mode=int(std::max_element(histogram.begin(),histogram.end())-histogram.begin());
    if(mode<100 || mode>=210) return 210;
    int uniform=0;
    for(int i=std::max(0,mode-8);i<=std::min(255,mode+8);++i) uniform+=histogram[i];
    return uniform*100>=length*90 ? mode-40 : 210;
}
inline int lastInkRow(const QImage &source) {
    if(source.isNull()) return -1;
    QImage image=source.convertToFormat(QImage::Format_RGB32);
    std::vector<int> rows(image.height(),210),columns(image.width(),210);
    std::vector<std::array<int,256>> colHist(image.width());
    for(int y=0;y<image.height();++y) {
        std::array<int,256> hist{};
        const QRgb *pixels=reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for(int x=0;x<image.width();++x) {int gray=qGray(pixels[x]);++hist[gray];++colHist[x][gray];}
        rows[y]=ruleThreshold(hist,image.width());
    }
    for(int x=0;x<image.width();++x) columns[x]=ruleThreshold(colHist[x],image.height());
    // An opaque plot can hide the middle of a template margin. Recognize
    // remaining long, thin pale segments rather than demanding a full-height
    // line. Keep this fallback vertical-only so pale handwritten text survives.
    std::vector<int> partial(image.width(),210);
    for(int x=0;x<image.width();++x) {
        if(columns[x]<210) continue;
        const auto &hist=colHist[x];
        int mode=100+int(std::max_element(hist.begin()+100,hist.begin()+210)-(hist.begin()+100));
        int count=0,run=0,longest=0;
        for(int y=0;y<image.height();++y) {
            int gray=qGray(image.pixel(x,y));
            if(std::abs(gray-mode)<=8) ++count;
            // Horizontal rule intersections darken the same vertical line.
            if(gray>=mode-60 && gray<=mode+8) {++run;longest=std::max(longest,run);}
            else run=0;
        }
        if(count*5>=image.height() && longest>=std::max(64,image.height()/10)) partial[x]=mode-40;
    }
    // A template margin is a thin line, not a shaded region or broad marker.
    for(int x=0;x<image.width();) {
        if(partial[x]==210) {++x;continue;}
        int end=x+1;while(end<image.width() && partial[end]<210)++end;
        if(end-x<=4)for(int i=x;i<end;++i)columns[i]=partial[i];
        x=end;
    }
    for(int y=image.height()-1;y>=0;--y) {
        const QRgb *pixels=reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for(int x=0;x<image.width();++x) {
            int threshold=std::min(rows[y],columns[x]);
            // Two translucent rules darken where they cross (e.g. 191 -> 143).
            if(rows[y]<210 && columns[x]<210)
                threshold=(rows[y]+40)*(columns[x]+40)/255-40;
            if(qGray(pixels[x])<threshold) return y;
        }
    }
    return -1;
}
