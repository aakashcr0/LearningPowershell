# Daily Health check script 

- Initially, we had to take the remote of every single voice recording server that we had and manually check whether recording was taking place or not. There were times were we had to manually make a test call.

- That was way too tedious, so we implemented an auto calling feature. First step towards automating. 

- This ensured that whatever health check that we had to do PRI wise was automated. We had to just check whether files were being created locally on the server.

- Got lazy again, manually checking every single server, so i decided to tinker around with powershell, seeing what I could do to automate this so I can check the status of every server in our Central Server.

- That's where it all started. After countless tutorials and refraining myself to make chatgpt make the entire script for me, I made this.

====================
Versioning -

-----------------------------------------------------------------------------------------------------------------------
Version 1:

- At first, I exported all the latest entries in the database into a txt file (horrendous, I know) and sent the txt file as a health check report.

- After finding out the beauty of csv files, I started learning towards displaying the file in a presentable enough way to call it a report

- Started off by displaying the latest entries on the database of that particular day.
-----------------------------------------------------------------------------------------------------------------------
Version 2:

- While displaying the latest entries made it look prettier, it was nowhere near concise or efficient. That was the next step.

- Next thing I had to work on was clarity; Seeing the report I had no idea if all the servers got their daily test call.

- Worked on displaying the location and the filename of the test call.
-----------------------------------------------------------------------------------------------------------------------
Version 3:

- Displaying the location and filenames of the test calls made it more efficient to find out which ones didn't get a test call, but it still didn't show it inside the report. We still had to cross reference a sheet to find out which ones didn't appear in the report.

- That's when one of my cousins gave me the idea of storing details into a json file. Yeah not that brilliant of an idea. I'm mad I didn't think of it myself.

- That was the next step I took. Stored all the Server names/Location names, IP addresses, and the corresponding extensions for that location.

- Understanding how to use JSON took a while but eventually got the hang of it. Like using a loop to enter a JSON objects was a pain to understand.

- Basically I took the location name to check the latest entries of that particular day and made sure all the Extension numbers of the test calls matched the basic extensions given in the json file. If it does, it changes the value of the 'status' as True, if it doesn't remains as False.

- Had to apply a different logic for 2 locations and implement that separately cause it was different from the other locations.

- And finally, using the resulting json file to make a csv file to send it as a report. The final report has each location with each PRI status. Clear, concise and to the point.

- And voila! We have a proper 'report' that shows which locations are up and down.
-----------------------------------------------------------------------------------------------------------------------
====================

Took me a good 5 months to come up with the script and learning how to use powershell. I wanted to learn powershell for my Azure certification anyway so it was the right time and situation to try and develop this script.


