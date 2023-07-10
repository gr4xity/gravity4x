Red [
	Needs: View
	Author: justin@gravity4x.com
	Title: "Unit Circle Demo"
]

; configuration
fps: 30				; frames per second
center: 320x320		; in pixels
r: center/x * 90%	; in pixels
theta: 0			; in degrees, starting position
delta: -1			; in degrees, iterator
star-radius: 36		; in pixels
planet-radius: 18	; in pixels

; color palette
yellow:	255.192.0
blue:	68.114.196
green:	112.173.71
orange:	237.125.49

; font definitions
large: make font! [
	size: 15
	anti-alias?: true
]

; function definitions
midpoint: function [
	"Returns the midpoint between two pairs of coordinates."
	a [pair!]
	b [pair!]
][
	as-pair
		(a/x + b/x) / 2
		(a/y + b/y) / 2
]

iterate: does [
	; determine center of "orbital" body relative to star
	body: add center to pair! reduce [
		r * cosine theta
		r * sine theta
	]

	; determine how ray from sun intersects planetary circle
	relative-radius: planet-radius / r
	shine-radius: to integer! round pi * planet-radius / 2
	shine-center: as-pair
		(relative-radius * center/x) + ((1 - relative-radius) * body/x)
		(relative-radius * center/y) + ((1 - relative-radius) * body/y)

	; find and reset dynamic components
	pos: next find graph/draw 'dyn
	clear pos/1

	; redraw dynamic components
	append pos/1 compose [
		; draw planetary body
		pen off
		fill-pen radial (shine-center) (shine-radius) 0 192.192.192 128.128.128 31.31.31
		planet: circle (body) (planet-radius)

		; highlight "orbital" angle
		line-width 2
		pen orange
		arc (center) (as-pair r r) 0 (either equal? theta 0 [0] [theta - 360])
		arc (center) ((as-pair r r) / 6) 0 (either equal? theta 0 [0] [theta - 360])
		text (center + ((as-pair r -1 * r) / 6)) (rejoin ["θ = " 360 - theta "°"])

		; plot radius
		pen green
		line (body) (center)
		text (midpoint body center) "r = √(x² + y²)"

		; plot x-line
		pen blue
		line (body) (d: as-pair center/x body/y)
		text (add 0x-4 midpoint body d) "x"

		; plot y-line
		pen yellow
		line (body) (d: as-pair body/x center/y)
		text (add 4x-16 midpoint body d) "y"
	]

	; iterate angle
	theta: theta + delta
	case [
		theta < 0		[theta: theta + 360]
		theta >= 360	[theta: theta - 360]
	]
]

view/tight compose [
	title "Chaoskampf Unit Circle Demo"
	graph: base (2 * center) black draw compose [
		font large
		pen off
		fill-pen radial (center) (star-radius) 0 255.255.255 255.255.0 0.0.0
		star: circle (center) (star-radius)

		pen white
		orbit: circle (center) (r)
		x-axis: line (as-pair 0 center/y) (as-pair 2 * center/y center/y)
		y-axis: line (as-pair center/x 0) (as-pair center/x 2 * center/x)

		; dynamic stuff redrawn each iteration
		dyn: [pen off]
	]
	rate fps on-time [iterate]	; update
	do [iterate]				; initialize
]

