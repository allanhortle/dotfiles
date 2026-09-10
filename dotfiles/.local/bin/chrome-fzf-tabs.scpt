-- Every tab of every window, as id, title and URL between unit separators,
-- one tab per group separator. Asking Chrome for each property once per
-- window, rather than once per tab, is what keeps this near 150ms; chrome-cli
-- asks per tab and takes almost a second.
if application "Google Chrome" is running then
	tell application "Google Chrome"
		set output to ""

		repeat with theWindow in windows
			set tabIds to id of tabs of theWindow
			set tabTitles to title of tabs of theWindow
			set tabUrls to URL of tabs of theWindow

			repeat with i from 1 to count of tabIds
				set output to output & (item i of tabIds) & (character id 31) & (item i of tabTitles) & (character id 31) & (item i of tabUrls) & (character id 30)
			end repeat
		end repeat

		return output
	end tell
end if
