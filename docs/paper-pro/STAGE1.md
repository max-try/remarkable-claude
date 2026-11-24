# Stage 1 on your Paper Pro (Windows)

Stage 1 checks three things before any real Claude question: that the add-on loader runs on your tablet's software (3.29.1.0), that our button patch fits it, and that screenshots come out right. The test build shows the Claude button and saves two photos of the page when you tap it. It doesn't talk to Claude, doesn't need an API key, and doesn't add anything to your notebooks.

It takes about 45 minutes, with one pause in the middle while I check a file you send me.

**Everything here can be undone by restarting the tablet.** Nothing is set to start by itself, and the tablet's system area isn't changed. Part 8 lists every way back.

## What you need

- The Paper Pro, charged, with its USB-C cable, and Wi-Fi on (the tablet downloads the helper tools).
- Your Windows computer and the tablet's password (Settings → General → Help → About → Copyrights and licenses).
- About 45 minutes.

**Two rules for the whole port:** don't install reMarkable software updates (each new version needs a new build), and don't go back to an older version.

### PowerShell, in one minute

All commands go into **PowerShell**, a text window that comes with Windows.

- **Open it:** click **Start** (the Windows logo), type `PowerShell`, click **Windows PowerShell**.
- **Paste** a command: right-click inside the window (or Ctrl + V), then press **Enter**.
- **Copy** what it printed: drag across the text with the mouse, then press **Enter** (or Ctrl + C).
- **Connect to the tablet:** plug in the cable, wake and unlock the tablet, then paste `ssh root@10.11.99.1` and press Enter. Type the tablet's password (it stays invisible as you type, that's normal) and press Enter. You're on the tablet when the line ends in `#`.
- **Disconnect:** type `exit` and press Enter. You're back on your computer.

In each part below, the heading says whether the commands go **on the tablet** (connected) or **on your computer** (not connected).

## Part 1: Back up your notes (on the tablet's screen)

1. Open **Settings** on the tablet and check that you're signed in and **sync** is on.
2. Wait a minute for syncing to finish. Then open the reMarkable app on your phone or computer and check that your notebooks are there.
3. For anything you can't lose, also export it as a PDF from the tablet's share menu.
4. Make a new, empty notebook called **Claude test**. All testing happens in it.

## Part 2: Install the helper tools (on the tablet)

Vellum is a small installer for tablet add-ons. It puts xovi (the add-on loader) and four of its extensions in your home folder.

1. Connect to the tablet (see "PowerShell, in one minute").
2. Paste this and press Enter. It downloads Vellum's installer and checks its fingerprint before running it:

   ```
   wget --no-check-certificate -O bootstrap.sh https://github.com/vellum-dev/vellum-cli/releases/latest/download/bootstrap.sh && echo "7b0deebc81b28a7d74d95c85e99a4a0a0f6ecaa5b9edb6b858ac61405978ebb9  bootstrap.sh" | sha256sum -c && bash bootstrap.sh
   ```

   It should print `bootstrap.sh: OK` and then Vellum's own messages. **If it says `FAILED`, stop** and send me what it printed: Vellum has published a new installer and I'll give you its new fingerprint.
3. Paste this and press Enter. It installs xovi and the extensions the plugin needs:

   ```
   /home/root/.vellum/bin/vellum add xovi qt-resource-rebuilder xovi-message-broker framebuffer-spy rm-shot
   ```

   If it asks a yes/no question, type `y` and press Enter. It's fine if it ends with a note saying you must run `xovi/rebuild_hashtable`: that's Part 3.

## Part 3: Make the notebook app's name map (on the tablet)

The button patch finds its place in the notebook app by internal names, which can change between software versions. This makes the list of names for your exact version, so I can check the patch fits.

1. Still connected, paste this and press Enter:

   ```
   bash /home/root/xovi/rebuild_hashtable
   ```

2. The tablet screen freezes or goes blank. That's expected. When PowerShell asks you to, press **Enter**.
3. If the tablet shows its passcode screen, enter your passcode on the tablet.
4. Wait until PowerShell prints `Hashtable rebuilt`. It usually takes under a minute.
5. The notebook app does **not** come back by itself after this. Paste this and press Enter to bring it back:

   ```
   systemctl start xochitl
   ```

6. Type `exit` and press Enter to disconnect.
7. Now on your computer, paste this and press Enter. It copies the name map into your **Downloads** folder (type the tablet's password when asked):

   ```
   scp root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab "$HOME\Downloads\hashtab-ferrari-3.29.1.0"
   ```

8. Open File Explorer (the folder icon on the taskbar), click **Downloads**, and attach `hashtab-ferrari-3.29.1.0` to our chat.

**Pause here until I reply.** I check that every name the button needs is in it. If one was renamed in 3.29, I fix the patch and send you a new test build, so you never install one that can't fit.

## Part 4: Get the test build (on your computer)

1. Download `ink-diary-stage1-test.zip` from the link I send you in the chat.
2. Open **Downloads** in File Explorer, right-click `ink-diary-stage1-test.zip`, choose **Extract All…**, and click **Extract**.
3. A folder called `ink-diary-stage1-test` opens. Check that you see `install.sh` and a folder called `bin` directly inside it. (If you see only another `ink-diary-stage1-test` folder, use that inner one in the next step and tell me.)

## Part 5: Copy it to the tablet (on your computer)

Make sure you're **not** connected to the tablet (if the line ends in `#`, type `exit`). Paste this and press Enter, then type the tablet's password:

```
scp -r "$HOME\Downloads\ink-diary-stage1-test" root@10.11.99.1:/home/root/
```

It lists the files as it copies them.

## Part 6: Install and start the test (on the tablet)

1. Connect to the tablet.
2. Paste this and press Enter:

   ```
   cd /home/root/ink-diary-stage1-test && sh install.sh
   ```

   It checks that this is a Paper Pro on 3.29.1.0, that no file was damaged on the way, and that the name map exists. It should end with `Installed the Stage 1 TEST build`. **If it prints anything else, stop and send it to me.** It hasn't installed anything in that case.
3. Paste this and press Enter. It restarts the notebook app with the add-ons loaded:

   ```
   systemctl reset-failed xochitl; bash /home/root/xovi/start
   ```

   The tablet screen goes back to your library after a few seconds. (The first part resets the tablet's count of app restarts. Without it, restarting the app 4 times within 10 minutes makes the tablet reboot itself as a safety measure.)
4. Leave PowerShell open and connected.

## Part 7: Tap the button (on the tablet's screen)

1. Hold the tablet upright (portrait). Open the **Claude test** notebook. Don't zoom in.
2. Look for a small square **Claude button** (the Claude star) on the right edge, a little above the bottom corner.
   - If it isn't there, go to "If something goes wrong" below.
3. Write `hello` somewhere in the middle of the page.
4. Tap the Claude button once. It turns into a black square while it works:
   - First it takes a photo of the page as you see it.
   - Then the toolbar disappears for a few seconds and it takes a second photo. **The toolbar coming back afterwards is part of the test.**
5. After about 10 seconds the button looks normal again and a message box above it says `Test done: 2 photos, 1620 x 2160…`. If you miss it, press and hold the button to show the message again.
6. Check: is the toolbar back where it was? Do the notebook's own buttons still work?

## Part 8: Send me the results (on your computer)

1. In PowerShell, type `exit` and press Enter to disconnect.
2. Paste this and press Enter (type the password when asked):

   ```
   scp -r root@10.11.99.1:/home/root/ink-diary-stage1 "$HOME\Downloads\"
   ```

3. Open **Downloads** → **ink-diary-stage1**. Attach all three files to our chat: `1-as-you-see-it.png`, `2-toolbar-hidden.png` and `report.json`.
4. Also tell me in a sentence: where the button appeared, whether the toolbar disappeared and came back, and anything that looked odd.

The photos show only the **Claude test** page. `report.json` holds measurements of the screen (sizes and positions), no personal data.

**Stage 1 passes when:** the button appears in a sensible spot, both photos are 1620 × 2160 and show your page, the second photo has no toolbar, and the toolbar came back. With your photos I set the final positions for Stage 2.

## Undo: every way back

| What you want | What to do |
|---|---|
| Everything back to normal, right now | Hold the power button and choose **Restart**. xovi never starts by itself, so the tablet comes up exactly as before. |
| Normal app without restarting | On the tablet: `bash /home/root/xovi/stock` |
| Remove the test plugin | On the tablet: `sh /home/root/ink-diary-stage1-test/uninstall.sh`, then restart the tablet |
| Delete the test photos | On the tablet: `rm -r /home/root/ink-diary-stage1` |

Vellum and xovi stay in the tablet's home folder, doing nothing until you run `xovi/start`. We'll use them again in Stage 2. If you ever want them gone completely, tell me and I'll give you the commands.

## If something goes wrong

- **The tablet screen is frozen or blank.** If you were making the name map, paste `systemctl start xochitl`. Otherwise, hold the power button and restart. Everything comes back as normal.
- **The tablet restarted on its own.** That's the safety measure from Part 6: the app was restarted too many times in a few minutes. Nothing is lost. Wait 10 minutes, and always use the `systemctl reset-failed xochitl; bash /home/root/xovi/start` line from Part 6.
- **No Claude button.** Connect to the tablet, paste this, and send me what it prints:

  ```
  journalctl -u xochitl -b --no-pager | grep -i -E "qmldiff|ink-diary|xovi" | tail -40
  ```

- **The toolbar didn't come back.** Close the notebook and open it again. If it's still missing, restart the tablet. Tell me either way: it's exactly what this test is for.
- **The message says `Test: …`** followed by an error. Copy the words and send them to me.
- **`ssh` or `scp` says "timed out" or "unreachable".** Unplug and replug the cable, wake the tablet, wait 10 seconds and try again.
- **`ssh` is "not recognized".** Your Windows is missing its built-in SSH. Tell me and I'll walk you through switching it on.
