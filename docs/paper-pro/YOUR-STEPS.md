# Your steps on the tablet (Windows)

Nothing here installs anything yet. There are two steps: one you can do now, and one that comes later, once the helper tools are installed in Stage 1.

You'll need the Paper Pro, its USB-C cable, and your Windows 10 or 11 computer. You type the commands into **PowerShell**, a text window that comes with Windows:

- Click the **Start** button (the Windows logo at the bottom of the screen), type `PowerShell`, and click **Windows PowerShell**. A blue or black window opens.
- **To paste** into it, right-click inside the window (or press Ctrl + V).
- **To copy** from it, drag across the text with the mouse to select it, then press Enter (or Ctrl + C).

## Step 1 (now): send me your tablet's details

This only reads a few facts off the tablet. It doesn't change anything.

1. Plug the tablet into your computer with the USB-C cable, and wake it up (unlock it if it has a passcode).
2. Open PowerShell as described above.
3. Type this and press Enter:

   ```
   ssh root@10.11.99.1
   ```

   If it asks "Are you sure you want to continue connecting (yes/no)?", type `yes` and press Enter. Then type the tablet's password (from Settings → General → Help → About → Copyrights and licenses on the tablet) and press Enter. The password stays invisible as you type. That's normal.
4. When you see a line ending in `#`, you're on the tablet. Copy this whole line, paste it in, and press Enter:

   ```
   cat /sys/devices/soc0/machine; echo; uname -m; grep -E '^(IMG_VERSION|VERSION_ID)=' /etc/os-release; ls /usr/lib/libQt6Core.so.*; ls /home/root/xovi 2>/dev/null || echo "xovi not installed"; sha256sum /usr/bin/xochitl
   ```

5. Select everything it printed, copy it, and paste it into our chat.
6. Type `exit` and press Enter to disconnect.

**What I'm checking:** that the tablet calls itself a Paper Pro ("ferrari"), that it runs 3.29.1.0, which Qt version it has (the build must match it), and a fingerprint of the notebook app so we notice if it ever changes.

**If step 3 doesn't connect** (it waits and then says "timed out" or "unreachable"): unplug and replug the cable, make sure the tablet is awake, wait 10 seconds, and try again. If it still fails, tell me what it printed.

**If step 3 says `ssh` is not recognized:** your Windows is missing its built-in SSH. Tell me and I'll walk you through switching it on (it's a free Windows feature, a few clicks in Settings).

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
5. Wait until PowerShell prints `Hashtable rebuilt`. This usually takes under a minute. Then type `exit` and press Enter.
6. You're now back on your own computer, in the same PowerShell window. Paste this and press Enter. It copies the list into your **Downloads** folder:

   ```
   scp root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab "$HOME\Downloads\hashtab-ferrari-3.29.1.0"
   ```

   Type the tablet's password again when asked.
7. Open File Explorer (the folder icon on the taskbar), click **Downloads**, and attach the file `hashtab-ferrari-3.29.1.0` to our chat.

**If something looks wrong:** hold the power button and restart the tablet. Everything comes back as normal, because nothing here starts automatically.
