#!/bin/sh
# push, play, ride down, capture town and cave, print client errors.  sh spike/cave_shot.sh <name>
cd "$(dirname "$0")/.."
python spike/night.py stop >/dev/null 2>&1
python spike/night.py push 2>&1 | tail -1
python spike/night.py play 2>&1 | tail -1; sleep 11
python spike/night.py shot "$1_town" | tail -1
python spike/night.py key Q >/dev/null; sleep 36
python spike/night.py shot "$1_cave" | tail -1
python spike/night.py lua Client 'local t={} for _,m in game:GetService("LogService"):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError or (m.messageType==Enum.MessageType.MessageWarning and string.find(m.message,"%[")) then t[#t+1]=string.sub(m.message,1,200) end end return #t.." issues: "..table.concat(t," | ")' | tail -2
