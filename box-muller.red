Red [
	Needs: View
	Author: justin@gravity4x.com
	Title: "Box-Muller Transform Demo"
]

; configuration
mean: 320x320		; in pixels: 2D translation
sdev: mean / 5		; in pixels: 2D scaling
deviations: 3		; number of standard deviations to plot
sps: 60				; samples per second

; color palette
yellow:	255.192.0
blue:	68.114.196
green:	112.173.71

; initialize summary statistics
stats: context [
	n: 0		; count number of samples
	x: y: 0.0	; aggregate weight in each dimension
]

; new random seed each time
random/seed now/time/precise

; function definitions
ln: :log-e	; alias natural log for convenience

standard-uniform: function [
	"Returns a pseudorandom float from standard uniform distribution"
][
	random 1.0
]

box-muller: function [
	{Returns a set of two independent pseudorandom floats
	from the standard normal distribution}
][
	theta: 2 * pi * standard-uniform				; uniformly random angle
	r: square-root -2 * (ln 1 - standard-uniform)	; exponentially random radius
	reduce [										; compute and return set
		r * cosine/radians theta
		r * sine/radians theta
	]
]

; event-driven UI
view/tight compose [
	title "Chaoskampf Box-Muller Transform Demo"
	graph: base black (2 * mean) draw compose [
		; initialize counter
		pen white
		samples: text 0x0 "n = 0"

		; plot population statistics
		pop-mean-x: line (as-pair mean/x 0) (as-pair mean/x 2 * mean/y)
		pop-mean-y: line (as-pair 0 mean/y) (as-pair 2 * mean/x mean/x)
		(collect [
			repeat d deviations [
				keep compose [pop-dev: circle (mean) (d * sdev/x) (d * sdev/y)]
			]
		])

		; initialize sample statistics
		pen green
		sample-mean-x: line (as-pair mean/x 0) (as-pair mean/x 2 * mean/y)
		sample-mean-y: line (as-pair 0 mean/y) (as-pair 2 * mean/x mean/x)
		(collect [
			repeat d deviations [
				keep compose [sample-dev: circle (mean) (d * sdev/x) (d * sdev/y)]
			]
		])
	] rate sps on-time [
		; iterate sample counter
		samples/3: rejoin ["n = " stats/n: stats/n + 1]

		; plot new 2D random sample
		point: box-muller					; pair of pseudorandom standard normals
		pixel: to pair! reduce [			; transform to pixel coordinates
			mean/1 + (sdev/1 * point/1)
			mean/2 + (sdev/2 * point/2)
		]
		append graph/draw compose [
			pen green
			circle (pixel) 1
		]

		; update histogram for x
		either pos: find graph/draw x: as-pair pixel/1 0 [
			pos/2/2: pos/2/2 + 1		; extend existing bar
		][
			append graph/draw compose [	; add new vertical bar
				pen blue
				hist-x: line (as-pair pixel/1 0) (as-pair pixel/1 1)
			]
		]

		; update histogram for y
		either pos: find graph/draw y: as-pair 0 pixel/2 [
			pos/2/1: pos/2/1 + 1		; extend existing bar
		][
			append graph/draw compose [	; add new horizontal bar
				pen yellow
				hist-y: line (as-pair 0 pixel/2) (as-pair 1 pixel/2)
			]
		]

		; update sample means
		stats/x: stats/x + point/1
		stats/y: stats/y + point/2
		smx: sample-mean-x/2/x: sample-mean-x/3/x: to integer! mean/1 + (sdev/1 * stats/x / stats/n)
		smy: sample-mean-y/2/y: sample-mean-y/3/y: to integer! mean/2 + (sdev/2 * stats/y / stats/n)

		; update sample standard deviations
		if stats/n > 1 [
			; sum squared deviations from each histogram
			parse graph/draw [
				(sd: context [x: 0.0 y: 0.0])
				any [
					to set-word! mark: (
						switch mark/1 [
							hist-x: [sd/x: sd/x + (mark/4/y * (power mark/4/x - smx 2))]
							hist-y: [sd/y: sd/y + (mark/4/x * (power mark/4/y - smy 2))]
						]
					) skip
				] to end
			]

			; redraw deviation ellipses
			parse graph/draw [
				(d: 0)
				any [
					thru quote sample-dev: mark: (
						d: d + 1
						mark/2: as-pair smx smy
						mark/3: d * (square-root sd/x / (stats/n - 1))
						mark/4: d * (square-root sd/y / (stats/n - 1))
					)
				] to end
			]
		]
	]
]
