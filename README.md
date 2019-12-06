# SlackBuilds

SlackBuilds are shell scripts that automate compiling and packaging software on Slackware Linux. 

While you can definitely compile and run software on Slackware without using slackbuilds, it
is the preferred way. The benefits can be seen in the self documenting nature of the scripts
as well as the ability to reduce repetitive tasks.



## Usage
```
cd /tmp
git clone https://github.com/tankmek/SlackBuilds.git
cd SlackBuilds/<appname>
wget $(grep DOWNLOAD= *.info | grep -Eoi '(http|https):[^"]+' )
md5sum <appname>.xx (compare with md5sum in .info file)
sudo su -
cd /tmp/SlackBuilds/<appname>
chmod a+x <appname>.SlackBuild
./<appname>.SlackBuild
```
