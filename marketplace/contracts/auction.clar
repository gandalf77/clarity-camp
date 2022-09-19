(use-trait nft-token 'SP2PABAF9.nft-trait.nft-trait')

(define-constant CONTRACT_ADDRESS 'ST1PQHQ.auction)

(define-constant ERR_NOT_SELLER (err u100))
(define-constant ERR_START_BID_LOWER_THAN_ZERO (err u101))

(define-map Started {nft: principal, nft-id: uint} bool)
(define-map Seller {nft: principal, nft-id: uint} principal)
(define-map EndsAt {nft: principal, nft-id: uint} uint)
(define-map Bids {nft: principal, nft-id: uint, bidder: principal} uint)
(define-map HighestBid {nft: principal, nft-id: uint} {bidder: principal, amount: uint})

(define-public (start (nft <nft-token>) (nft-id uint) (starting-bid uint) (days uint)) 
  (let
    (
      (nft-owner (try! (contract-call? nft get-owner nft-id)))
      (nft-principal (contract-of nft))
    )
      (asserts! (and (is-some nft-owner) (is-eq (unwrap! nft-owner ERR_NOT_SELLER) tx-sender)) ERR_NOT_SELLER)
      ;;(asserts! (> starting-bid u0) ERR_START_BID_LOWER_THAN_ZERO) -> not needed since it's defined as uint which can't be negative
      
      (map-set Started {nft: nft-principal, nft-id: nft-id} true)
      (map-set Started {nft: nft-principal, nft-id: nft-id} tx-sender
      (map-set EndsAt {nft: nft-principal, nft-id: nft-id} (+ block-height (* days u144)))      
      (map-set HighestBid {nft: nft-principal, nft-id: nft-id} {bidder: tx-sender, amount: starting-bid})

      (try! (contract-call? nft transfer nft-id sender CONTRACT_ADDRESS))

      (ok true)
  )
)