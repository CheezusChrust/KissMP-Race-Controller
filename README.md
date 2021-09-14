# KissMP Race Controller
A basic script allowing you to create timed multi-lap races, and start-to-finish sprints, with multiple people at a time.

Any instructions with ALLCAPS text means you replace the ALLCAPS with your own value.

## Instructions to install
- Drag the `racecontroller` folder into your KissMP server's addons folder
- Start your server

## Instructions to set up
- Join your server, and give yourself race controller admin by typing `/promote YOURNAMEHERE` in the server console
- Use `/writecfg` in either in-game chat or in the console to save your admin status
- In-game, you need to define where your finish line is. To do this:
  - Get in a vehicle, preferrably something small
  - Drive to one side of your finish line and type `/p1` in the chat
  - Drive to the opposide side (you're creating an invisible line) and type `/p2` in the chat
  - Type `/writecfg` to save the finish line location for the current map, so it persists on server restarts

## Instructions to start a race
- Type `/cfg laps NUMBERHERE` to define how many laps you want - set it to 1 lap if it's not a circuit
- Type `/add NAMEHERE` to add entrants to the race
- Type `/start` to begin the 5 second countdown in chat - when it says GO, start racing!
- Type `/reset` if you want to end the current race and start a new one - do this after every race

## List of all commands
### Console
- `/reloadcfg` - Reloads the configuration from the saved config file
- `/writecfg` - Writes the currently loaded configuration to a file
- `/promote NAMEHERE` - Promotes a user to admin
- `/demote NAMEHERE` - Demotes a user from admin

### In-game chat
- `/add NAMEHERE` - Adds an entrant to the race
- `/remove NAMEHERE` - Removes an entrant from the race
- `/reloadcfg` - Reloads the configuration from the saved config file
- `/writecfg` - Saves the currently loaded configuration to a file
- `/resetcfg` - Resets the active configuration to its defaults - `/writecfg` to save it
- `/p1` - Define the first point of the finish line
- `/p2` - Define the second point of the finish line
- `/cfg CONFIGOPTION` - Displays the current value of a configuration option - you can view `laps`, `minLapTime`, and `finishLineWidth`
- `/cfg CONFIGOPTION NEWVALUE` - Sets the value of a configuration option - you can change `laps`, `minLapTime`, and `finishLineWidth`
- `/start` - Starts the race with a 5 second countdown
- `/reset` - Resets the script, ending the current race - do this after every race
