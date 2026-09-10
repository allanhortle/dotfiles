-- Focuses or closes one tab: `osascript chrome-fzf-tab.scpt activate 12345`.
-- A tab id says nothing about where the tab sits, so both walk the windows
-- looking for it, reading the ids of a whole window at a time.
on run argv
	set theAction to item 1 of argv
	set theId to item 2 of argv

	tell application "Google Chrome"
		repeat with theWindow in windows
			set tabIds to id of tabs of theWindow

			repeat with i from 1 to count of tabIds
				if (item i of tabIds) as text is theId then
					if theAction is "close" then
						close tab i of theWindow
					else
						set active tab index of theWindow to i
						set index of theWindow to 1
						activate
					end if

					return
				end if
			end repeat
		end repeat
	end tell
end run
