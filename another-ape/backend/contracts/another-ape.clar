
(impl-trait .sip009.sip009)

(define-non-fungible-token another-ape uint)
(define-constant MINT_PRICE u50000000) ;; 50 STX
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ARTIST 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-constant ERR_OWNER_ONLY (err u101))
(define-constant ERR_NOT_TOKEN_OWNER (err u102))

(define-data-var last-token-id uint u0)
(define-data-var base-uri (string-ascii 100) "storageapi.fleek.co/87ae85d306af5-94fc-620cfc39f293-bucket/nft-example/another-ape") ;; points to the IPFS root

(define-read-only (get-last-token-id) 
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (id uint)) 
  ;; (concat (concat (var-get base-uri) "{id}") ".json")
  ;; client side where you'd handle swapping "{id}" based on input
  (ok (some (var-get base-uri)))
)
(define-read-only (get-owner (id uint)) 
  (ok (nft-get-owner? another-ape id))
)

(define-public (transfer (id uint) (sender principal) (receiver principal)) 
  (begin
    (asserts! (is-eq tx-sender sender) ERR_NOT_TOKEN_OWNER)
    ;; #[filter(id, receiver)]
    (nft-transfer? another-ape id sender receiver)
  )
)

(define-public (mint (recipient principal)) 
  (let
    (
      (id (+ (var-get last-token-id) u1))
      (portion-of-total (/ MINT_PRICE u2))
    )
    ;; #[filter(recipient)]
    (asserts! (is-eq tx-sender recipient) ERR_OWNER_ONLY)
    (try! (stx-transfer? portion-of-total recipient CONTRACT_OWNER))
    (try! (stx-transfer? portion-of-total recipient ARTIST))
    (try! (nft-mint? another-ape id recipient))
    (var-set last-token-id id)
    (ok id)
  )
)