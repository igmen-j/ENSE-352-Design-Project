Name: Justin Igmen
SID: 200364880
Class: ENSE 352

Project: Whack-a-mole

Decription: Whack-a-mole is a game is which the player tries to hit the moles that pop out as fast as possible.
	As the game progresses, the time allowed to the player to hit the mole decreases until the player is 
	either too slow or misses. In this project's case, the moles are the LEDs and the player's goal is to 
	push the corresponding buttons as fast as possible.

How to play: The startup pattern will go on until the player pushes any of the buttons.
	A random LED will turn and the user have a set amount of time allocated to hit the right button.
	This will continue for eight rounds. If the players manages to complete eight rounds, they will
	receive a winning pattern. If they lose, their current level in binary will blink. Following this, the
	game will go back to the startup pattern once again.

Problems encountered: I have encountered quite a few problems when writing this game. 
		Here are some of them and how I managed to solve them:
	1) Not enough registers to use.
		- In this game, I had to use all 12 general purpose registers. At one point I needed a few more.
		  Because of this, I utilized the stack to save some of the data would need later on.
	2) Determining the "best" reaction time.
		- To solve this, I had to use trial and error. I first decided to pick a very large reaction time.
		  I figured it was too easy for eight rounds. So, I picked a relatively small time.
		  After a few rounds, it got quite hard so I tested a few more values until I was satisfied
		  with the time. I managed to still win but I lost few times as well.
	3) Figuring out which light to turn on.
		- With Trevor's help, I have managed to write a pseudo-random code that picks an LED. This is
		  is dependent on the reaction time of the user.
	4) I could not figure out how to set up NumCycles. If given more time, I believe that I can solve this.

Game Parameters:
	The user can change the game parameters which are located at lines 70 to 78 of the code.