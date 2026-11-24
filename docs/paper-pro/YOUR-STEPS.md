# Your steps on the tablet

Nothing here installs anything yet. There are two steps: one you can do now, and one that comes later, once the helper tools are installed in Stage 1.

You'll need the Paper Pro, its USB-C cable, and a Mac (or Linux) computer. On a Mac, the app you type commands into is called **Terminal** (find it with Spotlight: press ⌘ + Space and type "Terminal").

## Step 1 (now): send me your tablet's details

This only reads a few facts off the tablet. It doesn't change anything.

1. Plug the tablet into your computer with the USB-C cable, and wake it up.
2. Open Terminal on your computer.
3. Type this and press Enter:

   ```
   ssh root@10.11.99.1
   ```

   If it asks "Are you sure you want to continue connecting?", type `yes` and press Enter. Then type the tablet's password (from Settings → General → Help → About → Copyrights and licenses) and press Enter. The password stays invisible as you type. That's normal.
4. When you see a line ending in `#`, copy this whole line, paste it in, and press Enter:

   ```
   cat /sys/devices/soc0/machine; echo; uname -m; grep -E '^(IMG_VERSION|VERSION_ID)=' /etc/os-release; ls /usr/lib/libQt6Core.so.*; ls /home/root/xovi 2>/dev/null || echo "xovi not installed"; sha256sum /usr/bin/xochitl
   ```

5. Select everything it printed, copy it, and paste it into our chat.
6. Type `exit` and press Enter to disconnect.

**What I'm checking:** that the tablet calls itself a Paper Pro ("ferrari"), that it runs 3.29.1.0, which Qt version it has (the build must match it), and a fingerprint of the notebook app so we notice if it ever changes.

## Step 2 (later, in Stage 1): make the notebook app's name map

Don't do this yet. It only works after the helper tools (xovi) are installed, which is the first part of Stage 1. I'll tell you when.

**What it is:** the Claude button is added by a small patch to the notebook app. The patch finds its place by the app's internal names, and those can change between software versions. This step makes a list of the names in your exact version (3.29.1.0), so I can check the patch fits.

1. Connect to the tablet as in Step 1 (steps 1 to 3).
2. Type this and press Enter:

   ```
   bash /home/root/xovi/rebuild_hashtable
   ```

3. It stops the notebook app, and the tablet screen goes blank for a moment. That's expected. When it asks you to, press Enter.
4. The notebook app starts on its own. If the tablet asks for its passcode, enter it on the tablet.
5. Wait until Terminal prints `Hashtable rebuilt`. This usually takes under a minute. Then type `exit` and press Enter.
6. Back in Terminal on your computer (now disconnected from the tablet), paste this and press Enter. It copies the list to your Desktop:

   ```
   scp root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab ~/Desktop/hashtab-ferrari-3.29.1.0
   ```

   Type the tablet's password again when asked.
7. Attach the file `hashtab-ferrari-3.29.1.0` from your Desktop to our chat.

**If something looks wrong:** hold the power button and restart the tablet. Everything comes back as normal, because nothing here starts automatically.
