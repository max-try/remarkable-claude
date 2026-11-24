# Your steps on the tablet (Windows)

Nothing here installs anything yet. Step 1 only reads facts off the tablet; Stage 1 comes after it, with its own guide.

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

## Step 2 (later): Stage 1

The rest happens in Stage 1, which has its own step-by-step guide: [STAGE1.md](STAGE1.md). It covers installing the helper tools, making the notebook app's name map, and trying the test button, with backup and undo steps.
