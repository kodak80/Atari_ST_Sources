;
; Exemple de programme r�sident en installant la routine en VBL-List.
; Cette routine affiche l'heure en permanence � la droite de la barre
; de menu.
; Ce programme peut �tre install� en AUTO, puisqu'il se loge � la place
; du vecteur VBL qu'il r�tablit � chaque fois.
; Au moment de l'ex�cution de la routine, l'adresse de la vraie routine VBL
; est empil�e. Il faut donc remettre le vecteur en haut de la pile avant
; de partir...
;
; Programmation : Pierre-Jean Goulier.
; � Start Micro & PJG / 1994.
; Assembleur : ASSEMBLE � BRAINSTORM
;
	
	TEXT
	
	INCLUDE	MACROSYS.S		; Des fichiers de macros.
	INCLUDE	UTILES.S
	
vbl_ptr	EQU	$456
	
	getrez				; Quelle r�solution ?
	tst	d0
	bne.s	start			; Pas de basse r�solution.
	cconws	#text_norez
	pterm0
start:	move	d0,rez			; sauvegarde de la r�solution.
	init_prgres			; Initialisation.
	move.l	d0,size			; Sauver la taille du programme.
	super_mode			; Passage en superviseur.
	move.l	d0,save_usp		; Sauvegarde du ptr.
	move.l	$70,vbl			; Sauver la vraie VBL.
	
	cconws	#text_good
	physbase			; Adresse d'affichage => Adr_Disp.
	add.l	#72,d0
	move	rez(pc),d1		; D1 = R�solution.
	cmp	#1,d1
	bne.s	.l1
	add.l	#72,d0			; Si Med-Rez => Adr_Disp +144.
	move	#2,jump			;            => Saut de plan = 2.
	move	#50,sync		;            => Synchro = 50 VBL.
.l1	move.l	d0,adr_disp
	tgettime			; R�cup�ration de l'heure syst�me.
	move	d0,d1			; D1 sert de sauvegarde.
	and	#31,d0
	mulu	#2,d0			; R�cup�rer les secondes
	move	d0,sec			; et les ranger.
	move	d1,d0
	asr	#5,d0			; R�cup�rer les minutes.
	and	#63,d0
	move	d0,min
	move	d1,d0
	move	#11,d2			; R�cup�rer les heures.
	asr	d2,d0
	and	#31,d0
	move	d0,heu
	move.l	(sp)+,a1		; Coucou, la revoil� !
	move.l	#display_time,$70	; Notre prg � la place de la VBL.
	user_mode save_usp
	move.l	size,d0
	ptermres d0			; Fin de programme r�sident.

display_time:
	move	sr,-(sp)		; Sauvegarde de tous les registres.
	movem.l	d0-a6,-(sp)
	moveq	#0,d3			; D3 = Offset d'affichage.
	move	heu(pc),d0		; Affichage de l'heure.
	bsr	cut_value
	inc	d3
	bsr	test_plan
	move	#10,d1			; Affichage des ":".
	bsr	print_char
	inc	d3
	bsr	test_plan
	move	min(pc),d0
	ext.l	d0
	bsr.s	cut_value
	inc	d3
	bsr	test_plan
	move	#10,d1
	bsr	print_char
	inc	d3
	bsr	test_plan
	move	sec(pc),d0
	ext.l	d0
	bsr.s	cut_value
	
	move	sec(pc),d0		; R�cup�rer les donn�es pour les actualiser.
	move	min(pc),d1
	move	heu(pc),d2
	move	counter(pc),d4		; Compteur de VBL.
	inc	d4
	cmp	sync(pc),d4		; 72/60/50 VBL = 1 seconde.
	bne.s	.lbl1
	inc	d0			; Incr�menter les secondes.
	moveq	#0,d4
	cmp	#60,d0
	bne.s	.lbl1
	moveq	#0,d0
	inc	d1			; Incr�menter les minutes.
	cmp	#60,d1
	bne.s	.lbl1
	moveq	#0,d1
	inc	d2			; Incr�menter les heures
	cmp	#24,d2
	bne.s	.lbl1
	moveq	#0,d2
	
.lbl1	move	d0,sec
	move	d1,min
	move	d2,heu
	move	d4,counter
	movem.l	(sp)+,d0-a6		; Restauration des registres.
	move	(sp)+,sr
	move.l	vbl(pc),-(sp)		; Remettre l'adresse VBL en pile.
	rts				; Fin de la routine.
	
cut_value:				; La valeur est dans D0.
	divu	#10,d0
	move	d0,d1
	bsr.s	print_char
	inc	d3
	bsr.s	test_plan
	swap	d0
	move	d0,d1
	bsr.s	print_char
	rts	
					; D3 = Offset d'affichage.
print_char:				
	move.l	adr_disp,a2		; Adresse d'affichage +
	adda.l	d3,a2			; offset => A2.
	move	rez(pc),d7
	cmp	#2,d7
	bne.s	.med
	mulu	#16,d1			; 16 bytes pour un caract�re.
	lea	monaco_16x8(pc),a1	; D�part de la table + nb d'octets
	adda.l	d1,a1			; => A1 = Adresse du caract�re.
	move	#15,d2			; D2 = compteur de lignes.
.loop	move.b	(a1)+,(a2)		; Affichage du caract�re.
	adda.l	#80,a2
	dbra	d2,.loop
	rts
	
.med	mulu	#8,d1			; 8 bytes pour un caract�re.
	lea	monaco_8x8(pc),a1	; D�part de la table + nb d'octets
	adda.l	d1,a1			; => A1 = Adresse du caract�re.
	move	#7,d2			; D2 = compteur de lignes.
.loop1	move.b	(a1),(a2)		; Affichage du caract�re plan par plan.
	move.b	(a1)+,2(a2)
	adda.l	#160,a2
	dbra	d2,.loop1
	rts

test_plan:
	btst	#0,d3			; On teste la parit� de D3.
	bne.s	.imp
	add	jump(pc),d3		; On saute au plan suivant.	
.imp	rts

	
	DATA

text_norez:
	DC.B	10,13,"Display-Time installation aborted !"
	DC.B	10,13,"Only High or Medium resolution."
	DC.B	10,13,"Sorry, press any key.",0
text_good:
	DC.B	10,13,"Display-Time installed ! / � PJG 94",0
text_nogood:
	DC.B	10,13,"Display-Time installation aborted !"
	DC.B	10,13,"8 programs already in VBL !",0

	EVEN
		
monaco_16x8:
	DC.B	$00,$00,$00,$3C,$66,$6E,$6E,$76,$76,$66,$66,$3C,$00,$00,$00,$00	; 0
	DC.B	$00,$00,$00,$18,$38,$18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$00	; 1
	DC.B	$00,$00,$00,$3C,$46,$06,$06,$0E,$1C,$38,$70,$7E,$00,$00,$00,$00	; 2
	DC.B	$00,$00,$00,$7E,$0C,$18,$3C,$06,$06,$06,$46,$3C,$00,$00,$00,$00	; 3
	DC.B	$00,$00,$00,$04,$0C,$1C,$2C,$4C,$8C,$FE,$0C,$0C,$00,$00,$00,$00	; 4
	DC.B	$00,$00,$00,$7E,$60,$60,$7C,$06,$06,$06,$46,$3C,$00,$00,$00,$00	; 5
	DC.B	$00,$00,$00,$1C,$20,$60,$7C,$66,$66,$66,$66,$3C,$00,$00,$00,$00	; 6
	DC.B	$00,$00,$00,$7E,$06,$06,$06,$0C,$18,$18,$18,$18,$00,$00,$00,$00	; 7
	DC.B	$00,$00,$00,$3C,$66,$66,$66,$3C,$66,$66,$66,$3C,$00,$00,$00,$00	; 8
	DC.B	$00,$00,$00,$3C,$66,$66,$66,$66,$3E,$06,$0C,$38,$00,$00,$00,$00	; 9
	DC.B	$00,$00,$00,$00,$00,$18,$18,$00,$00,$00,$18,$18,$00,$00,$00,$00	; :	
	
monaco_8x8:
	DC.B	$3C,$66,$6E,$76,$66,$66,$3C,$00	; 0
	DC.B	$18,$38,$18,$18,$18,$18,$18,$00	; 1
	DC.B	$3C,$66,$0E,$1C,$38,$70,$7E,$00	; 2
	DC.B	$7E,$0C,$18,$3C,$06,$46,$3C,$00	; 3
	DC.B	$0C,$1C,$2C,$4C,$7E,$0C,$0C,$00	; 4
	DC.B	$7E,$60,$7C,$06,$06,$46,$3C,$00	; 5
	DC.B	$1C,$20,$60,$7C,$66,$66,$3C,$00	; 6
	DC.B	$7E,$06,$0E,$1C,$18,$18,$18,$00	; 7
	DC.B	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
	DC.B	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
	DC.B	$18,$18,$00,$00,$00,$18,$18,$00	; :
	
sync:	DC.W	72
jump:	DC.W	0
	
	
	BSS

counter:
	DS.W	1	
heu:	DS.W	1
min:	DS.W	1
sec:	DS.W	1
rez:	DS.W	1	
size:	DS.L	1
vbl:	DS.L	1
save_usp:
	DS.L	1
adr_disp:
	DS.L	1
	