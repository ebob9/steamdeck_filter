steamdeck_filter
-------------------------

A quick shell script to install "super basic filtering" capability for the steamdeck. Best effort, don't bank your kids' future on this.


Steam Deck's "Family" supervision is great - except it allows my kids to watch Youtube unrestricted by going to "community" pages. This mod is meant to make that a bit more dificult by simply DNS blocking Youtube at the system level. They don't have the passcodes to log in, so it's effective for that situation only.


To install:
1. Login to the steamdeck in desktop mode.
2. Open up `kconsole`.
3. From here, set a password for the `deck` account by running `passwd deck`
   * You will be prompted for a password twice. If it's already set, and you don't remember it, you will need to search how to recover it.
4. SUDO to root by running `sudo su -`
   * adasd
5. Clone this repo - `git clone https://github.com/ebob9/steamdeck_filter.git`
6. cd into the directory `steamdeck_filter`
7. Run the script `bash ./after_upgrade.sh` to install the filter.

Note - after every patch you'll need to run the script again, as steam updates will wipe out the changes.

