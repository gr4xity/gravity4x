Red []
#include %graphecs.red

config: context [
    components: [
        demand  [
            quantity: 0
            willingness-to-pay: $0
        ]
        supply  [
            quantity: 0
            marginal-cost: $0
        ]
    ]
    entities: [
        Apples  [supply [quantity: 3]]
        e       [demand []]
        f       [demand []]
        g       [demand []]
    ]
    conditions: [
        has-demand? [demand?] [demand/willingness-to-pay > 0]
        in-supply? [supply?] [supply/quantity > 0]
        can-sell? [in-supply? in-demand?] [1 < length? in-demand]
    ]
    connections: [
        in-demand [in-supply?] [has-demand?] [
            right/demand/willingness-to-pay
        ]
    ]
    edge-systems: [
        in-demand [
            weight < left/supply/marginal-cost
        ][  a/weight < b/weight ; lowest bids first
        ][  print [rid "didn't meet reserve price for" lid]
            right/demand/willingness-to-pay: $0
        ]
    ]
    entity-systems: [
        auction [can-sell?] [
            sort/compare in-demand func [a b] [ ; operate on entity's graph
                a/weight > b/weight
            ]
            winner: in-demand/1/right   ; highest bidder
            price: in-demand/2/weight   ; second price
            print [ ; output auction results to console
                winner/id "wins at" price ":"
                in-demand/1/weight - price "consumer surplus"
                "+" price - supply/marginal-cost "profit"
            ]
            supply/quantity: supply/quantity - 1    ; transfer quantity from supply to demand, sating WTP
            winner/demand/quantity: winner/demand/quantity + 1
            winner/demand/willingness-to-pay: $0
        ]
    ]
    initializers: [
        random-demand [demand?] [
            random/seed now/time/precise
        ][  demand/willingness-to-pay: random $10][]
        random-auction [supply?] [][
            supply/marginal-cost: random $2
            print ["How Do You Like Them" self/id "???"]
        ][  while [not empty? collections/can-sell?] [
                execute
            ]
        ]
    ]
]

second-price-auction: graphecs/create 'second-price-auction config
do in second-price-auction 'play
