"""Print the distinct error lines of both logs (Play running).   python spike/errs.py"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,220)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')"
for w in ("Client", "Server"): print(w, "errors:", night.lua(ERR, w).splitlines()[-1])
