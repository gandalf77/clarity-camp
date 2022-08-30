
;; blockpost
;; contract that writes a post on chain for a small fee

;; wallet that gets the STX fee
(define-constant contract-owner (as-contract tx-sender)) ;;tx-sender = ST23242
;; as-contract tx-sender = ST23242.blockpost

;; how much to post
(define-constant price u1000000) ;; 1 STX

;; variable that holds the total number of posts made to the chain
(define-data-var total-posts uint u0)

;; principal is the key and the string is the value (the blockpost)
(define-map post principal (string-utf8 500))

(define-read-only (get-total-posts) 
  (var-get total-posts)
)

;; input parameter is user of principal type
(define-read-only (get-post (user principal)) 
  (map-get? post user) ;; 'SP23294923 : "This is my message"
)

(define-public (write-post (message (string-utf8 500)))
  (begin 
    (try! (stx-transfer? price tx-sender contract-owner))
    (map-set post tx-sender message)
    (var-set total-posts (+ (var-get total-posts) u1)) ;; incrementing by 1
    (ok "SUCCESS")
  )
)

