;PCBIOS, a PC BIOS spoof for Chip16
;Shendo November, 2014.
;
;r0 - PAD 1 Status
;r1 - PAD 1 D-PAD timeout value
;r2 - Unused
;r3 - Unused
;r4 - Unused
;r5 - Unused
;r6 - Current scene
;r7 - Currently selected item index
;Subroutines:
;r8 - Scratchpad
;r9 - Scratchpad
;Functions:
;ra - 1st argument
;rb - 2nd argument
;rc - 3rd argument
;rd - 4th argument
;re - 5th argument
;rf - Return value
;
;Menu data in memory (in words/ushort)
;0x00 - Menu type
;0x02 - Menu text
;0x04 - Current value index (optional)
;0x06 - Submenu address (optional)
;0x08 - Allowed values address (optional)
;0x0A - Scene number (optional)
;
;Menu types
;0x0000 - No further items
;0x0001 - Parent menu
;0x0002 - Value selector
;0x0003 - Change scene on activation
;
;Scenes
;0 - Booting scene
;1 - Main scene
;2 - Standard scene
;3 - Advanced scene
;4 - Power scene
;5 - Health scene
;6 - Peripherals scene
;7 - Message scene

PAD_UP			equ 1													;Gamepad buttons
PAD_DOWN		equ 2
PAD_LEFT		equ 4
PAD_RIGHT		equ 8
PAD_SELECT	equ 16
PAD_START		equ 32
PAD_A				equ 64
PAD_B				equ 128

importbin palette.bin 0 48 palette				;CGA Palette
importbin font.bin 0 20480 font						;Monospace font
importbin selector.bin 0 112 selector			;Menu selector

main:																			;Entry point
	pal palette															;Load CGA Palette

	ldi r0, 0																;Gamepad status
	ldi r1, 0																;Gamepad timeout
	ldi r6, 1																;Default scene
	ldi r7, 0																;First item is selected

scene_selector:														;Scene manager (branch point)
	ldm r0, 0xFFF0													;Get PAD1 status

	mov r8, r6									;Copy current scene

	subi r8, 0									;Scene ZERO
	;jz scene_main

	subi r8, 1									;Scene 1
	jz scene_main

	subi r8, 1									;Scene 2
	jz scene_standard

	subi r8, 1									;Scene 3
	;jz scene_main

	subi r8, 1									;Scene 4
	;jz scene_main

	subi r8, 1									;Scene 5
	;jz scene_main

	subi r8, 1									;Scene 6
	jz scene_peripherals

	subi r8, 1									;Scene 7
	;jz scene_main
s_s_bsod:										;No more scenes to show, Black Screen Of Death
	ldi ra, 5									;Load string X coordinate
	ldi rb, 5									;Load string Y coordinate
	ldi rc, string_no_scene		;Load string memory location
	ldi rd, 0									;Don't show selector
	call draw_string					;Draw string on screen (Blinking line, Black Screen Of Death)

	ldi ra, 10								;Wait 10 frames
	call wait_frames

	cls

	ldi ra, 10								;Wait 10 frames
	call wait_frames

	jmp scene_selector				;Go to next scene

;SCENES
scene_main:										;Main screen of the setup utility
	cls													;Clear screen
	bgc #1											;Blue background

	ldi ra, 43									;Load string X coordinate
	ldi rb, 5										;Load string Y coordinate
	ldi rc, string_info					;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 30									;Load string X coordinate
	ldi rb, 200									;Load string Y coordinate
	ldi rc, string_ctrl_a				;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 30									;Load string X coordinate
	ldi rb, 215									;Load string Y coordinate
	ldi rc, string_ctrl_b				;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 184									;Load string X coordinate
	ldi rb, 200									;Load string Y coordinate
	ldi rc, string_ctrl_c				;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 166									;Load string X coordinate
	ldi rb, 215									;Load string Y coordinate
	ldi rc, string_ctrl_d				;Load string memory location
	ldi rd, 0										;Don't show selector
	;call draw_string						;Draw string on screen

	ldi ra, -2									;Load window X coordinate
	ldi rb, 22									;Load window Y coordinate
	ldi rc, 36									;Load width (in characters)
	ldi rd, 11									;Load height (in characters)
	call draw_window						;Draw window on screen

	ldi ra, -2									;Load window X coordinate
	ldi rb, 184									;Load window Y coordinate
	ldi rc, 36									;Load width (in characters)
	ldi rd, 4										;Load height (in characters)
	call draw_window						;Draw window on screen

	mov rd, r7									;Copy currently selected menu item

	ldi ra, 30									;Load menu X coordinate
	ldi rb, 50									;Load menu Y coordinate
	ldi rc, menu_main						;Load menu location
	;ldi rd, 0									;Load selected index
	call draw_menu							;Draw menu on screen

	mov rd, r7									;Copy currently selected menu item
	subi rd, 5									;Remove offset of the main menu

	ldi ra, 166									;Load menu X coordinate
	ldi rb, 50									;Load menu Y coordinate
	ldi rc, menu_secondary			;Load menu location
	;ldi rd, -1									;Load selected index
	call draw_menu							;Draw menu on screen

	vblnk

gamepad:										;Gamepad routines
	tsti r1, 0xFF							;Check if timeout should be decremented
	jnz g_decr_timeout

	andi r0, 0xF								;Isolate D-PAD
	jz scene_selector						;Skip gamepad check if there are no buttons pressed

	addi r1, 0									;Update flags
	jnz scene_selector					;Timeout is active, skip reading controller

g_check_up:
	tsti r0, PAD_UP
	jz g_check_down

	addi r7, 0									;Update flags
	jz g_check_down							;Do not allow negative values

	subi r7, 1									;Decrease menu offset
	ldi r1, 7										;Set PAD 1 timeout

g_check_down:
	tsti r0, PAD_DOWN
	jz g_check_left

	cmpi r7, 9									;Update flags
	jz g_check_left							;Do not allow values higher then 10

	addi r7, 1									;Increase menu offset
	ldi r1, 7										;Set PAD 1 timeout

g_check_left:
	tsti r0, PAD_LEFT
	jz g_check_right

	cmpi r7, 5									;Update flags
	jl g_check_right						;Only allow if menu selector is on the right side

	subi r7, 5									;Decrease menu offset
	ldi r1, 7										;Set PAD 1 timeout

g_check_right:
	tsti r0, PAD_RIGHT
	jz scene_selector

	cmpi r7, 4									;Update flags
	jg scene_selector						;Only allow if menu selector is on the left side

	addi r7, 5									;Increase menu offset
	ldi r1, 7										;Set PAD 1 timeout
	jmp scene_selector

g_decr_timeout:
	subi r1, 1									;Decrement gamepad timeout value
	jmp scene_selector

scene_standard:								;Standard CMOS features scene
	cls													;Clear screen
	bgc #1											;Blue background

	ldi ra, 43									;Load string X coordinate
	ldi rb, 5										;Load string Y coordinate
	ldi rc, string_info					;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 60									;Load string X coordinate
	ldi rb, 18									;Load string Y coordinate
	ldi rc, string_info_standard	;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, -2									;Load window X coordinate
	ldi rb, 32									;Load window Y coordinate
	ldi rc, 36									;Load width (in characters)
	ldi rd, 13									;Load height (in characters)
	call draw_window						;Draw window on screen

	vblnk

	jmp scene_selector

scene_peripherals:						;List all peripherals found on the system
	cls													;Clear screen
	bgc #1											;Blue background

	ldi ra, 43									;Load string X coordinate
	ldi rb, 5										;Load string Y coordinate
	ldi rc, string_info					;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 110									;Load string X coordinate
	ldi rb, 18									;Load string Y coordinate
	ldi rc, string_info_peripherals	;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, -2									;Load window X coordinate
	ldi rb, 32									;Load window Y coordinate
	ldi rc, 36									;Load width (in characters)
	ldi rd, 13									;Load height (in characters)
	call draw_window						;Draw window on screen

	ldi ra, 20									;Load string X coordinate
	ldi rb, 50									;Load string Y coordinate
	ldi rc, string_port1				;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	ldi ra, 20									;Load string X coordinate
	ldi rb, 66									;Load string Y coordinate
	ldi rc, string_port2				;Load string memory location
	ldi rd, 0										;Don't show selector
	call draw_string						;Draw string on screen

	vblnk

	jmp scene_selector

;SUBROUTINES
get_controller_status:				;Read status of the controller | ushort GetControllerStatus(ushort port)
	ldi rb, 0xFFFF							;Load check value
	stm rb, ra									;Store value to I/O port location in memory
	vblnk												;Wait for controller ports to be filled
	ldm rf, ra									;Fetch return value from memory
	jmp fret

draw_menu:										;Draw interactive menu on screen | void DrawMenu(ushort X, ushort Y, ushort* menus, short selectedIndex)
	ldi rf, 0										;Set up index counter
 
d_m_start:
	ldm re, rc									;Load menu type
	addi re, 0									;Check if this is valid menu
	jz fret											;Break subroutine if not

	addi rc, 2									;Get string pointer
	ldm re, rc									;Load menu item (string location)

	push ra											;Store parameters on stack
	push rb
	push rc
	push rd
	push rf

	cmp rd, rf									;Check if current item should be selected
	jnz d_m_not_sel

d_m_sel:
	ldi rd, 1										;Item is selected
	jmp d_m_draw

d_m_not_sel:
	ldi rd, 0										;Item is not selected
	jmp d_m_draw

d_m_draw:
	mov rc, re									;Copy string pointer as third parameter
	call draw_string

	pop rf											;Restore parameters
	pop rd
	pop rc
	pop rb
	pop ra

	addi rc, 10									;Point to the next menu
	addi rb, 26									;Increase Y offset
	addi rf, 1									;Increment index counter

	jmp d_m_start

d_m_set_selected:							;Select currenly processed menu item
	ldi rd, 1										;Item is selected
	jmp fret

draw_string:									;Draw string on screen | void DrawString(ushort X, ushort Y, char* string, bool selected);
	mov rf, rd									;Copy 4th parameter for later use
d_s_start:
	ldm rd, rc									;Load character from memory
	andi rd, #FF								;Only the lo byte is needed

	addi rd, 0									;Update flags
	jz fret											;Null reached, break subroutine

	mov re, rd									;Copy data to scratchpad
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address

	addi rf, 0									;Update flags
	jz d_s_skip_selector				;Skip drawing selector if parameter is set to 'false'

	subi ra, 2									;Decrease X offset to center selector
	subi rb, 2									;Decrease Y offset to center selector
	spr #1206										;Set 12x18 px sprites
	drw ra, rb, selector				;Draw 16x7 selector part on screen
	addi, ra, 2									;Restore X offset
	addi, rb, 2									;Restore Y offset

d_s_skip_selector:						;Go here if selector should't be shown
	spr #1005										;Set 10x16 px sprites
	drw ra, rb, re							;Draw 10x16 character on the set coordinates

	addi rc, 1									;Increase memory offset
	addi ra, 9									;Increase X coordinate

	jmp d_s_start								;Loop routine for another character

draw_window:									;Draw a rectangle | void DrawWindow(ushort X, ushort Y, ushort W, ushort H);
	spr #1005										;Set 10x16 px sprites

	mov rf, ra									;Copy initial X coordinate
	subi rc, 1									;Remove last X character since it will be drawn manually
	subi rd, 1									;Remove last Y character since it will be drawn manually

	mov r8, rc									;Copy width
	muli r8, 9									;Each character is 9 pixels wide
	add r8, ra									;Add initial X offset

	mov r9, rd									;Copy height
	muli r9, 16									;Each character is 16 pixels high
	add r9, rb									;Add initial Y offset

	ldi re, 201									;Draw upper left corner
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw ra, rb, re							;Draw 10x16 character on the set coordinates

	ldi re, 187									;Draw upper right corner
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw r8, rb, re							;Draw 10x16 character on the set coordinates

	ldi re, 188									;Draw lower right corner
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw r8, r9, re							;Draw 10x16 character on the set coordinates

	ldi re, 200									;Draw lower left corner
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw ra, r9, re							;Draw 10x16 character on the set coordinates

	addi ra, 9									;Start from first X character
	subi rc, 1									;Remove already drawn last character

d_w_x:
	ldi re, 205									;Draw horizontal piece
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw ra, rb, re							;Draw 10x16 character on the set coordinates
	drw ra, r9, re							;Draw 10x16 character on the set coordinates

	subi rc, 1									;Decrement width
	jz d_w_fix									;Go to next segment

	addi ra, 9									;Increase X coordinate
	jmp d_w_x										;Loop routine for another character

d_w_fix:
	addi rb, 16									;Start from first Y character
	subi rd, 1									;Remove already drawn last character

d_w_y:
	ldi re, 186									;Draw vertical piece
	muli re, 80									;Each character is 80 bytes long
	addi re, font								;Apply offset to font address
	drw r8, rb, re							;Draw 10x16 character on the set coordinates
	drw rf, rb, re							;Draw 10x16 character on the set coordinates

	subi rd, 1									;Decrement height
	jz fret											;Go to next segment

	addi rb, 16									;Increase Y coordinate
	jmp d_w_y										;Loop routine for another character

wait_frames:									;Wait for required number of frames | void DrawWindow(ushort frameNum);
	vblnk												;Wait for VBLANK
	subi ra, 1									;Decrement wait number
	jz fret											;Value is zero, stop waiting
	jmp wait_frames							;Wait for another frame

fret:													;Subroutine return function
	ret

;MENUS
menu_main:
	dw 0x0003									;Change scene type
	dw string_menu_1					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0001									;Scene number

	dw 0x0003									;Run subroutine type
	dw string_menu_2					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0002									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_3					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0003									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_4					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0004									;No subroutine (yet)

	dw 0x0003									;Change scene type
	dw string_menu_5					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0005									;Scene number

	dw 0x0000									;Ending item
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000

menu_secondary:
	dw 0x0003									;Run subroutine type
	dw string_menu_6					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0000									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_7					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0000									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_8					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0000									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_9					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0000									;No subroutine (yet)

	dw 0x0003									;Run subroutine type
	dw string_menu_10					;Menu text
	dw 0x0000									;Menu holds no values
	dw 0x0000									;No submenus
	dw 0x0000									;No allowed values
	dw 0x0000									;No subroutine (yet)

	dw 0x0000									;Ending item
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000
	dw 0x0000

;STRINGS
string_no_scene:
	db "-"
	db 0x00

string_ctrl_a:
	db "A:Confirm"
	db 0x00

string_ctrl_b:
	db "B:Back"
	db 0x00

string_ctrl_c:
	db 24
	db 25
	db 26
	db 27
	db ":Select"
	db 0x00

string_ctrl_d:
	db "SELECT:Color"
	db 0x00

string_info:
	db "Chip16 CMOS Setup Utility"
	db 0x00

string_info_standard:
	db "Standard CMOS features"
	db 0x00

string_info_peripherals:
	db "Peripherals"
	db 0x00

string_port1:
	db "Port 1: 8 button controller"
	db 0x00

string_port2:
	db "Port 2: 8 button controller"
	db 0x00

string_menu_1:
	db 16
	db " Standard"
	db 0x00

string_menu_2:
	db 16
	db " Advanced"
	db 0x00

string_menu_3:
	db 16
	db " Power"
	db 0x00

string_menu_4:
	db 16
	db " C16 Health"
	db 0x00

string_menu_5:
	db 16
	db " Peripherals"
	db 0x00

string_menu_6:
	db "Load Fail-Save"
	db 0x00

string_menu_7:
	db "Load Optimized"
	db 0x00

string_menu_8:
	db "Password"
	db 0x00

string_menu_9:
	db "Save & Exit"
	db 0x00

string_menu_10:
	db "Exit"
	db 0x00
