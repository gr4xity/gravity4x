Red [
	Needs: View
	Author: justin@gravity4x.com
	Title: "Box-Muller Transform Demo"
	Version: 0.2
	History: [
		0.2 "Performance optimizations, window is resizable (restarting sim)"
	]
]

; configuration
mean: 320x320		; population mean in pixels: 2D translation
sdev: mean / 5		; population standard deviation in pixels: 2D scaling
deviations: 3		; number of standard deviations to plot
sps: 60				; samples per second

; color palette
yellow:	255.192.0
blue:	68.114.196
green:	112.173.71

; new random seed each time
random/seed now/time/precise

; function definitions
ln: :log-e	; alias natural log for convenience

standard-uniform: func [
	"Returns a pseudorandom float from standard uniform distribution"
][
	random 1.0
]

box-muller: func [
	{Returns a set of two independent pseudorandom floats
	from the standard normal distribution}
	/local r theta
][
	theta: 2 * pi * standard-uniform				; uniformly random angle
	r: square-root -2 * (ln 1 - standard-uniform)	; exponentially random radius
	reduce [										; compute and return set
		r * cos theta
		r * sin theta
	]
]

redraw: func [
	"Resets stats and returns new draw code"
][
	stats: context [
		n: 0			; count number of samples
		x: y: 0.0		; aggregate weight in each dimension
	]
	compose [
		; initialize counter
		pen white
		samples: text 0x0 "n = 0"

		; plot population statistics
		pop-mean-x: line (as-pair mean/x 0) (as-pair mean/x 2 * mean/y)
		pop-mean-y: line (as-pair 0 mean/y) (as-pair 2 * mean/x mean/y)
		(collect [
			repeat d deviations [
				keep compose [pop-dev: circle (mean) (d * sdev/x) (d * sdev/y)]
			]
		])

		; initialize sample statistics to population values
		pen green
		sample-mean-x: line (as-pair mean/x 0) (as-pair mean/x 2 * mean/y)
		sample-mean-y: line (as-pair 0 mean/y) (as-pair 2 * mean/x mean/x)
		(collect [
			repeat d deviations [
				keep compose [sample-dev: circle (mean) (d * sdev/x) (d * sdev/y)]
			]
		])
		
		; draw empty histogram, combining data storage and rendering logic
		(compose/deep [
			pen blue
			hist-x: [
				(collect [
					repeat x 2 * mean/x [
						keep/only compose/deep [line (as-pair x 0) (as-pair x 0)]
					]
				])
			]
			pen yellow
			hist-y: [
				(collect [
					repeat y 2 * mean/y [
						keep/only compose [line (as-pair 0 y) (as-pair 0 y)]
					]
				]
			)]
		])
	]
]

; event-driven UI
view/tight/flags compose [
	title "Chaoskampf Box-Muller Transform Demo"
	on-resize [
		; update population stats
		mean: face/size / 2
		sdev: mean / 5

		; resize and restart graph
		graph/size: face/size
		graph/image: canvas: make image! reduce [graph/size black]
		graph/draw: redraw
	]
	graph: base (2 * mean) draw redraw rate sps on-time [
		; iterate sample counter
		samples/3: rejoin ["n = " stats/n: stats/n + 1]

		; plot new 2D random sample
		point: box-muller					; pair of pseudorandom standard normals
		pixel: to pair! reduce [			; transform to pixel coordinates
			mean/1 + (sdev/1 * point/1)
			mean/2 + (sdev/2 * point/2)
		]
		canvas/(pixel): green				; poke pixel

		; update histogram for x
		hist: pick graph/draw/hist-x pixel/x
		hist/3/y: 1 + hist/3/y

		; update histogram for y
		hist: pick graph/draw/hist-y pixel/y
		hist/3/x: 1 + hist/3/x

		; estimate and update linear sample statistics: sum and mean
		stats/x: stats/x + point/1
		stats/y: stats/y + point/2
		sm: to pair! reduce [	; transform and update pixel values
			sample-mean-x/2/x: sample-mean-x/3/x: to integer! round mean/1 + (sdev/1 * stats/x / stats/n)
			sample-mean-y/2/y: sample-mean-y/3/y: to integer! round mean/2 + (sdev/2 * stats/y / stats/n)
		]

		; estimate and update nonlinear sample statistics: standard deviation
		if stats/n > 1 [
			; sum weighted squared deviations from histograms
			sd: context [x: 0.0 y: 0.0]
			foreach line graph/draw/hist-x [
				sd/x: sd/x + (line/3/y * (power line/3/x - sm/x 2))
			]
			foreach line graph/draw/hist-y [
				sd/y: sd/y + (line/3/x * (power line/3/y - sm/y 2))
			]

			; redraw deviation ellipses (applying Bessel's correction)
			parse graph/draw [
				(d: 0)
				any [
					thru quote sample-dev: mark: (
						d: d + 1
						mark/2: sm
						mark/3: d * (square-root sd/x / (stats/n - 1))
						mark/4: d * (square-root sd/y / (stats/n - 1))
					)
				] to end
			]
		]
	]
][resize]
