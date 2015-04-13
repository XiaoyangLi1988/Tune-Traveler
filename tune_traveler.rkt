#lang racket/gui
(require sgl
         sgl/gl
         sgl/gl-vectors)

; Constants
(define F_WIDTH 600)
(define F_HEIGHT 600)
(define GRID_SIZE 15)
(define TILE_SIZE (/ F_HEIGHT GRID_SIZE))
(define GRID_OFF (/ (abs (- F_WIDTH F_HEIGHT)) 2))

; Resize the display window.
(define (resize w h)
  (glViewport 0 0 w h)
  (set! F_WIDTH w)
  (set! F_HEIGHT h)
  (set! TILE_SIZE (/ F_HEIGHT GRID_SIZE))
  (set! GRID_OFF (/ (abs (- F_WIDTH F_HEIGHT)) 2)))

; Compute F = G + H
(define (compG p t)
  (let ([xOff (- (send t getCol) (send p getCol))]
        [yOff (- (send t getRow) (send p getRow))])
    (define (cg)
      (if (and (not (= xOff 0)) (not (= yOff 0)))
          14
          10))
    (cg)))
(define (compH t e)
  (let ([xOff (abs (- (send t getCol) (send e getCol)))]
        [yOff (abs (- (send t getRow) (send e getRow)))])
    (define (ch)
      (* (+ xOff yOff) 10))
    (ch)))
(define (compF g h)
  (+ g h))

; Class to represent grid tiles.
(define tile%
  (class object%
    (init row col walkable)
    (super-new)
    
    (define myRow row)
    (define myCol col)
    (define canWalk walkable)
    
    ; Field getters/setters.
    (define/public (getRow)
      myRow)
    (define/public (getCol)
      myCol)
    (define/public (isWalkable)
      canWalk)
    (define/public (setWalk v)
      (set! canWalk v))
    
    ; Other fun stuff.
    (define/public (draw)
      (cond ((not canWalk)
             (begin (glColor3f 0.4 0.4 0.4)
                    (glVertex3f (+ (* myCol TILE_SIZE) GRID_OFF) (* myRow TILE_SIZE) 0.0)
                    (glVertex3f (+ (+ (* myCol TILE_SIZE) TILE_SIZE) GRID_OFF) (* myRow TILE_SIZE) 0.0)
                    (glVertex3f (+ (+ (* myCol TILE_SIZE) TILE_SIZE) GRID_OFF) (+ TILE_SIZE (* myRow TILE_SIZE)) 0.0)
                    (glVertex3f (+ (* myCol TILE_SIZE) GRID_OFF) (+ TILE_SIZE (* myRow TILE_SIZE)) 0.0)))
            (else #f)))))

; Used to access elements of a one-dimensional array representing a two-dimensional array.
(define (get row col)
  (cond ((or (> row (- GRID_SIZE 1)) (< row 0)) (error "Row out of bounds!"))
        ((or (> col (- GRID_SIZE 1)) (< col 0)) (error "Column out of bounds!")))
  (define (h li)
    (list-ref li (+ (* row GRID_SIZE) col)))
  h)

; Used to create a one-dimensional array that represents a two-dimensional array.
(define (createGrid rows cols)
  (let ([row 0]
        [col 0])
    (define (cg li)
      (cond ((<= col (- cols 1))
             (begin (set! col (+ col 1))
                    (cg (append li (list (new tile% [row row] [col (- col 1)] [walkable #t]))))))
            ((<= row (- rows 1))
             (begin (set! row (+ row 1))
                    (set! col 0)
                    (cg li)))
            (else li)))
    (cg '())))

; The grid that will hold the game objects.
(define GRID (createGrid GRID_SIZE GRID_SIZE))

; Create walls around the grid.
(begin (for ([i GRID_SIZE])
         (send ((get 0 i) GRID) setWalk #f)
         (send ((get (- GRID_SIZE 1) i) GRID) setWalk #f)
         (send ((get i 0) GRID) setWalk #f)
         (send ((get i (- GRID_SIZE 1)) GRID) setWalk #f)))

; Define the start and end position.
(define start (cons 3 4))
(define goal (cons 10 9))

; Define the player's current position. Subject to change throughout execution.
(define player (cons 3 4))

; Helper function for drawing tiles at a given row and column.
(define (drawTile r c)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF) (* r TILE_SIZE) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF TILE_SIZE) (* r TILE_SIZE) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF TILE_SIZE) (+ (* r TILE_SIZE) TILE_SIZE) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF) (+ (* r TILE_SIZE) TILE_SIZE) 0.0))

; Called after the window renders. Used to update objects.
(define (update)
  #t)

; Render everything to the frame.
(define (draw-gl)
  ; Clear the screen and draw a blank black background.
  (glClearColor 0.0 0.0 0.0 0.0)
  (glClear GL_COLOR_BUFFER_BIT)
 
  (glShadeModel GL_SMOOTH)
  
  ; Create an orthogonal projection that draws from the top-left to the bottom-right.
  (glMatrixMode GL_PROJECTION)
  (glLoadIdentity)
  (glOrtho 0.0 F_WIDTH F_HEIGHT 0.0 -1.0 1.0)
  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity)
  
  (define center (list (/ F_WIDTH 2) (/ F_HEIGHT 2)))
  (define off 80)
  
  ; Go through the actual grid and find relevant objects to draw.
  (glBegin GL_QUADS)
  (map (lambda (t) (send t draw)) GRID)
  (glEnd)
  
  ; Draw the start and end position squares, as well as the player.
  (glBegin GL_QUADS)
  
  ; Start
  (glColor3f 0.0 1.0 0.0)
  (drawTile (cdr start) (car start))
  
  ; End
  (glColor3f 1.0 0.0 0.0)
  (drawTile (cdr goal) (car goal))
  
  ; Draw the "player".
  (define r (cdr player))
  (define c (car player))
  (define s (/ TILE_SIZE 4))
  (glColor3f 0.0 0.0 1.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF s) (+ (* r TILE_SIZE) s) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF TILE_SIZE (- s)) (+ (* r TILE_SIZE) s) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF TILE_SIZE (- s)) (+ (* r TILE_SIZE) TILE_SIZE (- s)) 0.0)
  (glVertex3f (+ (* c TILE_SIZE) GRID_OFF s) (+ (* r TILE_SIZE) TILE_SIZE (- s)) 0.0)
  
  (glEnd) ; Stop drawing quads.
  
  ; Draw the grid.
  (glColor3f 1.0 1.0 1.0)
  (glBegin GL_LINES)
  (for ([row (- GRID_SIZE 1)])
    (begin (glVertex3f GRID_OFF (* (+ row 1) TILE_SIZE) 0.0)
           (glVertex3f (- F_WIDTH GRID_OFF) (* (+ row 1) TILE_SIZE) 0.0)))
  (for ([col (- GRID_SIZE 1)])
    (begin (glVertex3f (+ (* (+ col 1) TILE_SIZE) GRID_OFF) 0.0 0.0)
           (glVertex3f (+ (* (+ col 1) TILE_SIZE) GRID_OFF) F_HEIGHT 0.0)))
  (glVertex3f GRID_OFF 0.0 0.0)
  (glVertex3f (- F_WIDTH GRID_OFF) 0.0 0.0)
  (glVertex3f GRID_OFF F_HEIGHT 0.0)
  (glVertex3f (- F_WIDTH GRID_OFF) F_HEIGHT 0.0)
  (glVertex3f GRID_OFF 0.0 0.0)
  (glVertex3f GRID_OFF F_HEIGHT 0.0)
  (glVertex3f (- F_WIDTH GRID_OFF) 0.0 0.0)
  (glVertex3f (- F_WIDTH GRID_OFF) F_HEIGHT 0.0)
  (glEnd))

; Contains methods for drawing to and updating the canvas on the screen.
(define my-canvas%
  (class* canvas% ()
    (inherit refresh with-gl-context swap-gl-buffers)
    
    ; Used to update objects on the screen.
    (define/public (STEP)
      (update)
      (refresh)
      (sleep/yield 1/60)
      (queue-callback (lambda _ (send this STEP)) #f))
    
    ; Used to call the draw function.
    (define/override (on-paint)
      (with-gl-context (λ() (draw-gl) (swap-gl-buffers))))
    
    ; Called when the user resizes the screen.
    (define/override (on-size width height)
      (with-gl-context (λ() (resize width height))))
    
    (super-instantiate () (style '(gl)))))

(define win (new frame% [label "Tune Traveler"]
                        [min-width F_WIDTH] 
                        [min-height F_HEIGHT]))
(define gl  (new my-canvas% [parent win]))
 
(send win show #t)
(send gl STEP)