"""Client and server warnings 10 s into Play (2026-11-27): a module whose start() failed only warns ("[Name] error").   python spike/warn_check.py"""
import time
import night as N
Q = ("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageWarning or m.messageType==Enum.MessageType.MessageError then "
     "t[#t+1]=string.sub(m.message,1,200) end end return #t..' | '..table.concat(t,' || ')")
N.play(True); time.sleep(10)
print("client:", N.lua(Q, "Client").splitlines()[-1][:4000])
print("server:", N.lua(Q, "Server").splitlines()[-1][:4000])
N.play(False)
