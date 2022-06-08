* * * D R A F T * * * D R A F T * * * D R A F T * * * D R A F T * * * D R A F T * * *

                     Upgrade Pi-Star Buster to Bullseye!
                                In Place!

Yes, you read that right! You CAN upgrade a working (or new build) image of Pi-Star
from its current Debian Buster implementation to a Debian Bullseye implementation
in place.  But... there's always a butt ... there's no quarantee the upgrade will
work in all cases, just because.

                -- For experienced Pi-Star/Linux users only! --

Because an in-place upgrade such as this is involved, complicated, this undertaking
should not be taken lightly.  You need to have a good working knowledge of Linux
and the Linux CLI as well as some understanding of how Pi-Star works.

The intended audience here are those who want to get a leg up on the next Debian
platform for Pi-Star and are willing to spend the time testing the resulting upgrade,
looking for problems and possible solutions, and otherwise contribute feedback and
suggestion to make the upgrade a success for everyone.

You can, of course, simply wait until an official release of Pi-Star/Bullseye is
announced, or you can join the crowd at the forefront of the coming changes.

Presented herein is a BASH script that automates (organizes) the steps involved.
It assumes you are working with the lastest Pi-Star version (4.1.6).

This upgrade was worked out on a Rpi 4b system with a USB drive and direct ethernet
connection. Upgrading using a micro-SD should be possible but has not been tested.
Wireless over WiFi may be problematic as the process may disconnect as components
are replaced/restarted so has not be fully tested.

As always, make a backup - or use a clone - of your system before attempting this
upgrade.

* * * D R A F T * * * D R A F T * * * D R A F T * * * D R A F T * * * D R A F T * * *