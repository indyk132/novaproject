--[[
	Session Exporter for Nova
	Exports logged session data to an HTML file.
]]

local SessionExporter = {}

function SessionExporter:ProcessCalls(AllCalls, SessionData, UpdateProgress)
	local Events = {}
	local StringMap = {}
	local StringIndex = 0

	local function InternString(str)
		if not StringMap[str] then
			StringMap[str] = StringIndex
			StringIndex += 1
		end
		return StringMap[str]
	end

	local Total = #AllCalls
	for i, CallData in ipairs(AllCalls) do
		if UpdateProgress then
			UpdateProgress(i / Total)
		end

		local event = {
			Type = InternString(CallData.Type or "Unknown"),
			Remote = InternString(CallData.RemoteName or "Unknown"),
			ClassName = InternString(CallData.ClassName or "Unknown"),
			Time = CallData.Time or 0,
			ArgCount = CallData.ArgCount or 0,
		}

		table.insert(Events, event)
	end

	return Events, StringMap
end

function SessionExporter:ExportSessionToHTML(Events, StringMap, SessionData)
	local ReverseStringMap = {}
	for str, idx in pairs(StringMap) do
		ReverseStringMap[idx] = str
	end

	local eventsJson = wax.shared.HttpService:JSONEncode(Events)
	local stringMapJson = wax.shared.HttpService:JSONEncode(ReverseStringMap)

	local SessionId = SessionData.SessionId or wax.shared.HttpService:GenerateGUID(false)
	local StartTime = SessionData.StartTime or 0
	local EndTime = SessionData.EndTime or tick()
	local PlaceId = SessionData.PlaceId or game.PlaceId
	local Duration = string.format("%.1f", EndTime - StartTime)

	local HTML = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nova - Session Viewer</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace;
            background: #0d1117;
            color: #c9d1d9;
        }
        .header {
            background: #161b22;
            border-bottom: 1px solid #30363d;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .brand {
            font-weight: 700;
            font-size: 16px;
            color: #58a6ff;
        }
        .session-info {
            font-size: 12px;
            color: #8b949e;
        }
        .content {
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        .stats {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 16px;
            flex: 1;
        }
        .stat-label {
            font-size: 11px;
            color: #8b949e;
            text-transform: uppercase;
            margin-bottom: 4px;
        }
        .stat-value {
            font-size: 24px;
            font-weight: 700;
            color: #f0f6fc;
        }
        .event-table {
            width: 100%;
            border-collapse: collapse;
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 6px;
            overflow: hidden;
        }
        .event-table th {
            background: #21262d;
            padding: 8px 12px;
            text-align: left;
            font-size: 12px;
            color: #8b949e;
            font-weight: 600;
        }
        .event-table td {
            padding: 6px 12px;
            border-top: 1px solid #21262d;
            font-size: 13px;
        }
        .type-incoming { color: #3fb950; }
        .type-outgoing { color: #f78166; }
        .footer {
            padding: 12px 20px;
            text-align: center;
            color: #484f58;
            font-size: 11px;
            border-top: 1px solid #30363d;
            margin-top: 40px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="brand">Nova - Session Viewer</div>
        <div class="session-info">Session / ]] .. SessionId .. [[</div>
    </div>
    <div class="content">
        <div class="stats">
            <div class="stat-card">
                <div class="stat-label">Total Events</div>
                <div class="stat-value">]] .. tostring(#Events) .. [[</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Duration</div>
                <div class="stat-value">]] .. Duration .. [[s</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Place ID</div>
                <div class="stat-value">]] .. tostring(PlaceId) .. [[</div>
            </div>
        </div>
        <table class="event-table">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Type</th>
                    <th>Remote</th>
                    <th>Class</th>
                    <th>Time</th>
                    <th>Args</th>
                </tr>
            </thead>
            <tbody id="eventBody"></tbody>
        </table>
    </div>
    <div class="footer">Generated by Nova Remote Spy</div>
    <script>
        const events = ]] .. eventsJson .. [[;
        const stringMap = ]] .. stringMapJson .. [[;
        const body = document.getElementById('eventBody');
        events.forEach((e, i) => {
            const type = stringMap[e.Type] || 'Unknown';
            const typeClass = type === 'Incoming' ? 'type-incoming' : 'type-outgoing';
            body.innerHTML += `<tr>
                <td>${i + 1}</td>
                <td class="${typeClass}">${type}</td>
                <td>${stringMap[e.Remote] || 'Unknown'}</td>
                <td>${stringMap[e.ClassName] || 'Unknown'}</td>
                <td>${e.Time.toFixed(3)}s</td>
                <td>${e.ArgCount}</td>
            </tr>`;
        });
    </script>
</body>
</html>]]

	return HTML
end

return SessionExporter
