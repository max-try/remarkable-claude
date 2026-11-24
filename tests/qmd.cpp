// Loads the button from inkDiary.qmd into a stand-in notebook screen and checks its
// position against src/layout.h, and that hiding the toolbar is undone afterwards.
// The real notebook screen comes from the tablet; this only checks our own QML.
#include <cassert>
#include <iostream>
#include <QFile>
#include <QGuiApplication>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QRegularExpression>
#include "../src/layout.h"

static QString insertBody() {
    QFile file("inkDiary.qmd");
    assert(file.open(QIODevice::ReadOnly));
    QString qmd=QString::fromUtf8(file.readAll());
    const int start=qmd.indexOf("INSERT {")+QString("INSERT {").size();
    const int end=qmd.lastIndexOf("END TRAVERSE");
    QString body=qmd.mid(start,end-start);
    body=body.left(body.lastIndexOf('}'));  // the INSERT block's own closing brace
    // The message broker only exists on the tablet; the polling Timer already catches its absence.
    body.remove(QRegularExpression("XoviMessageBroker \\{[^}]*\\}"));
    return body;
}

static QQuickItem *load(QQmlEngine &engine, const QString &notebook, QObject **root) {
    QQmlComponent component(&engine);
    component.setData(("import QtQuick 2.15\nItem {\n    id: root\n    width: 1620\n    height: 2160\n" + notebook +
                       "\n" + insertBody() + "\n}\n").toUtf8(), QUrl("qrc:/DocumentView.qml"));
    if(component.isError()) {for(const auto &e:component.errors()) std::cerr<<e.toString().toStdString()<<"\n";}
    assert(!component.isError());
    *root=component.create();
    assert(*root);
    auto *control=(*root)->findChild<QQuickItem *>("inkDiaryControl");
    assert(control);
    return control;
}

int main(int argc, char **argv) {
    QGuiApplication app(argc,argv);
    QQmlEngine engine;
    {
        // A notebook with the 3.28 ids: a toolbar whose visibility follows `shown`, and a zoom control.
        QObject *root=nullptr;
        auto *control=load(engine,
            "    Rectangle { id: toolbar; objectName: \"toolbar\"; property bool shown: true; visible: shown; width: 112; height: 2160 }\n"
            "    Rectangle { id: zoomButton; objectName: \"zoom\"; width: 80; height: 80 }\n",&root);
        const QRectF rect=control->mapRectToScene(QRectF(0,0,control->width(),control->height()));
        assert(rect==QRectF(1524,1928,72,72));
        // The masks cover the button (and Send, 16 px to its left) with a 12 px margin.
        assert(diaryButtonRect()==rect.toRect().adjusted(-12,-12,12,12));
        assert(diarySendButtonRect()==QRect(1524-16-120,1928,120,72).adjusted(-12,-12,12,12));
        auto *toolbar=root->findChild<QQuickItem *>("toolbar");
        auto *zoom=root->findChild<QQuickItem *>("zoom");
        assert(control->property("diaryToolbarFound").toBool());
        assert(!control->property("diaryToolbarHidden").toBool());
        control->setProperty("diaryHideToolbar",true);
        assert(!toolbar->isVisible() && !zoom->isVisible());
        assert(control->property("diaryToolbarHidden").toBool());
        control->setProperty("diaryHideToolbar",false);
        assert(toolbar->isVisible() && zoom->isVisible());
        // The toolbar's own binding survives: closing it still hides it afterwards.
        toolbar->setProperty("shown",false);
        assert(!toolbar->isVisible());
        toolbar->setProperty("shown",true);
        assert(toolbar->isVisible());
        delete root;
    }
    {
        // A notebook where the ids were renamed: the button still loads and reports it.
        QObject *root=nullptr;
        auto *control=load(engine,"    Rectangle { id: somethingElse; width: 112; height: 2160 }\n",&root);
        assert(!control->property("diaryToolbarFound").toBool());
        control->setProperty("diaryHideToolbar",true);
        assert(!control->property("diaryToolbarHidden").toBool());
        delete root;
    }
    std::cout<<"PASS: button position matches the capture masks; toolbar hides and comes back; renamed toolbar is reported, not fatal\n";
    return 0;
}
