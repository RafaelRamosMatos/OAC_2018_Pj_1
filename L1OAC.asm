#L1_OAC_TB
#Ana Carolina Souza 15/0004907
#Antônio Freire A. Malta 
#Rafael Ramos De Matos 15/0145683

#Base de endereco bitmap display = heap 0x10040000
#menu de interface com usuario no terminal
#Mars deve esta na mesma pasta onde se encontra a imagem de entrada
#nome do arquivo de entrada com a extensao

.data
	
	filename: .space 64
	filename2: .space 64
	mensagem_final: .asciiz "Qual o nome do arquivo da imagem de saida?\n"
	mensagem_inicial: .asciiz "Qual o nome do arquivo da imagem?\n"
	mensagem_novamente: .asciiz "Deseja realizar mais algum efeito nesta imagem?\n1-Sim\n2-Nao\n"
	mensagem_menu1: .asciiz "Qual efeito voce gostaria de realizar na imagem?\n1-Efeito de borramento\n2-Efeito de extracao de bordas\n3-Efeito de binarizacao por limiar\n"
	mensagem_menu1_1: .asciiz "Qual a mascara usar para o efeito?\n1-borra_imagem_2x2\n2-borra_imagem_4x4\n"
	mensagem_menu1_2: .asciiz "Qual a mascara usar para o efeito?\n1-Horizontal\n2-Vertical\n3-Cruz\n4-Quadrado 3x3\n"
	mensagem_menu1_2_1: .asciiz "Qual a intensidade do bytes R para a mascara? de 0 a 255\n"
	mensagem_menu1_2_2: .asciiz "Qual a intensidade do bytes G para a mascara? de 0 a 255\n"
	mensagem_menu1_2_3: .asciiz "Qual a intensidade do bytes B para a mascara? de 0 a 255\n"
	mensagem_menu1_3: .asciiz "Qual o metodo usar para o efeito?\n1-Constante\n2-OTSU\n3-Interrativa\n4-Limiar por equilíbrio\n"
	mensagem_menu2: .asciiz "Opcao incorreta. Tente novamente.\n"
	men: .space 2
	
	.align 2
	men2: .space 4
	men1: .space 52
	vetorEdge0: .space 12
	vetorEdge1: .space 12
	vetorEdge2: .space 12
	pixel_image: .space 12
	result: .space 4
	buffer_extractor: .space  10240
	buffer_extractor2: .space 10240
	R: .float 0.21 # constade para deixar cinza
	G: .float 0.72# constade para deixar cinza
	B: .float 0.07# constade para deixar cinza

	tam_arquivo: .word 0
	offset: .word 0
	largura: .word 0
	altura: .word 0
	soma1: .word 0
	soma2: .word 0
	soma3: .word 0
	soma4: .word 0
	passada_2x2: .word 0
	passada_4x4: .word 0
.text

	l.s $f0, R
	l.s $f1, G
	l.s $f2, B
	
	la $a0, mensagem_inicial
	li $v0, 4
	syscall
	
	la $a0, filename
	li $a1, 64
	li $v0, 8
	syscall
	
	li $t1, '\n'
	loop_prepara_nome:
		lbu $t0, 0($a0)
		beq $t0, $t1, fim_loop_prepara_nome
		add $a0, $a0, 1
		j loop_prepara_nome
	fim_loop_prepara_nome:
		sb $zero, 0($a0)
	
	la $a0, filename
	li $a1, 0
	jal open_file
	
	move $s0, $v0 #salva o descritor original do arquivo em $s0
	move $a0, $v0
	la $a1, men
	li $a2, 2
	jal read_file
	
	li $a2, 52
	la $a1, men1
	jal read_file
	
	#variaveis globais 
	lw $s1, 0($a1) # Tamanho do arquivo
	lw $s2, 8($a1) # Offset para comeÃƒÂ§o dos dados da imagem
	sub $s1, $s1, $s2 #tamanho da imagem em bytes
	lw $s3, 16($a1) # Largura da imagem em pixels
	lw $s4, 20($a1) # Altura da imagem em pixels 

	li $t2, 0x10040000 #Prepara o endereco da memoria heap para armazenar a imagem
	mul $t3, $s4, $s3
	mul $t3, $t3, 4
	add $t2, $t2, $t3 #Abrindo espaÃ§o para imagem (Arquivo comeca dos pixels inferiores)
	mul $t3, $s3, 4
	move $t0, $0
	
load_image:
	beq $t0, $s1, exit_load_image
	sub $t2, $t2, $t3
	move $t1, $0
	loop_load_image: 
		beq $t1, $s3, exit_loop_load_image
		li $a2, 3
		la $a1, men2
		jal read_file
	
		lw $t4, 0($a1)
		sw $t4, 0($t2)
		addi $t0, $t0, 3 
		addi $t2, $t2, 4
		addi $t1, $t1, 1
		j loop_load_image
	exit_loop_load_image:
		sub $t2, $t2, $t3
		j load_image
exit_load_image:  
	move $a0, $s0
	jal close_file
	li $a0, 0x10040000
	move $a1, $s1 
	jal save_original_image
	jal menu
	jal save_image_effect
	jal close_file
	
	novamente:
	la $a0, mensagem_novamente
	li $v0, 4
	syscall
	
	li $v0, 5
	syscall
	
	li $t0, 1
	li $t1, 2
	beq $t0, $v0, menu_novamante
	beq $t1, $v0, exit
	la $a0, mensagem_menu2
	li $v0, 4
	syscall
	j novamente 
	
	menu_novamante: 
	move $a0, $fp
	move $a1, $s1
	jal show_original_image
	jal menu
	jal save_image_effect
	jal close_file
	j novamente

####################################################################################################################################	
open_file: #Funcao abre arquivo que recebe como argumento em $a0 o endereco onde esta armazenado o 
	# nome do arquivo e em $a1 a flag (0 - read, 1-write) e retorna em $v0 0 descritor do arquivo.
	
	li $v0, 13
	li $a2, 0
	syscall
	jr $ra

####################################################################################################################################
read_file: #Funcao ler arquivo que recebe como argumento em $a0 o descritor do arquivo, em $a1 o endereco do buffer 
	# na memoria e em $a2 o numero de bytes a serem lidos e retorna em $v0 o numero de bytes lidos ou 0 caso final do arquivo.
	
	li $v0, 14
	syscall
	jr $ra

####################################################################################################################################
write_file:
	
	li $v0, 15
	syscall
	jr $ra
	
###################################################################################################################################	
close_file:#Funcao fecha arquivo que recebe como argumento em $a0 o descritor do arquivo.
		
	li $v0, 16
	syscall
	jr $ra
	
###################################################################################################################################	
exit: 
	li $v0, 10
	syscall 

###################################################################################################################################
save_original_image: #Funcao que recebe como parametros: 1) o endereco da memoria onde foi carregada a imagem em $a0(memoria heap 0x10040000)
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao decrementa $gp de acordo com o tamanho da imagem(largura*altura*4(word))pega 
#os bytes da imagem original carregada na memoria heap e salva na pilha depois carrega o valor de $gp em $fp e retorna $fp como uma 
#barreira para que demais procedimentos nao ultrapasse $fp e extravie os dados referentes a imagem original.

	add $t0, $0,$0
	move $t1, $a0 #EndereÃ§o da memoria heap
	
	#Decrementando a pilha com um tamanho da imagem
	move $t2, $sp
	div $t3, $a1, 3 #$a1/3 == Quantidade de pixels da imagem
	add $t3, $t3, $a1 #$t3 = 4vezes a quantidade de pixels(tamanho da imagem na memoria heap)(pois cada pixel possui 4 bytes, ou uma word)
	sub $sp, $sp, $t3 #Abre o espaÃ§o na pilha

	Loop_save_image:#Loop que carrega word da memoria heap e salva na pilha de cima para baixo
		beq $t0, $a1, end_save_original_image
		lw $t3, 0($t1)
		sw $t3, 0($t2)
		addi $t2, $t2, -4
		addi $t1, $t1, 4
		addi $t0, $t0, 3
		j Loop_save_image
end_save_original_image:
	move $fp, $sp #Carrega em $fp o limite onde comeÃ§a os dados da imagem original na pilha
	jr $ra
#######################################################################################################################################

show_original_image: # Funcao que recebe como parametros: 1) O endereÃ§o de delimitador $fp da pila onde se encontra a imagem original em $a0
#2) o tamanho da imagem em bytes em $a1($s1). Esta funcao carrega a imagem original na memoria heap para ser mostrada no bitmap display


	move $t0, $a0
	
	#Soma o endereÃ§o de base da memoria heap com o tamanho da imagem original (abre espaÃ§o na memoria heap)
	li $t1, 0x10040000
	div $t2, $a1, 3
	add $t2, $t2, $a1
	add $t1, $t1, $t2
	move $t2, $zero
	Loop_show_image: #Loop que desempilha os pixels de tras pra frente e ja carrega na posicao correta na memoria heap
		beq $t2, $a1, exit_show_original_image
		lw $t3, 0($t0)
		sw $t3, 0($t1)
		addi $t0, $t0, 4
		addi $t1, $t1, -4
		addi $t2, $t2, 3
		j Loop_show_image
exit_show_original_image:
		jr $ra

#######################################################################################################################################	
save_image_effect:

	la $a0, mensagem_final
	li $v0, 4
	syscall
	
	la $a0, filename2
	li $a1, 64
	li $v0, 8
	syscall
	
	li $t1, '\n'
	loop_prepara_nome_saida:
		lbu $t0, 0($a0)
		beq $t0, $t1, fim_loop_prepara_nome_saida
		add $a0, $a0, 1
		j loop_prepara_nome_saida
	fim_loop_prepara_nome_saida:
		sb $zero, 0($a0)

	la $a0, filename2 #abrindo um arquivo para escrita
	li $a1, 1
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal open_file
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	move $s0, $a0
	move $a0, $v0 #salva o descritor original do arquivo em $a0
	la $a1, men
	li $a2, 2
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal write_file
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	la $a1, men1
	li $a2, 52
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal write_file
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	li $t0, 0x10040000 #Prepara o endereco da memoria heap para armazenar a imagem
	mul $t1, $s4, $s3
	mul $t1, $t1, 4
	add $t0, $t0, $t1 #Abrindo espaÃ§o para imagem (Arquivo comeca dos pixels inferiores)

	mul $t1, $s3, 4
	move $t2, $0
	
load_image_effect:
	beq $t2, $s1, exit_load_image_effect
	sub $t0, $t0, $t1
	move $t3, $0
	loop_load_image_effect: 
		beq $t3, $s3, exit_loop_load_image_effect
		
		la $a1, men2
		lw $t4, 0($t0)
		sw $t4, 0($a1)
		li $a2, 3
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal write_file
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		addi $t2, $t2, 3 
		addi $t0, $t0, 4
		addi $t3, $t3, 1
		j loop_load_image_effect
	exit_loop_load_image_effect:
		sub $t0, $t0, $t1
		j load_image_effect
exit_load_image_effect:  
	move $a0, $s0
	jr $ra
	
###################################################################################################################################
menu:

	la $a0, mensagem_menu1
	li $v0, 4
	syscall
	
	li $v0, 5
	syscall
	
  	li $t0, 1
  	li $t1, 2
  	li $t2, 3
  	bne $t0, $v0, nao_borramento
  		la $a0, mensagem_menu1_1
		li $v0, 4
		syscall
		li $v0, 5
		syscall
		
		slt $t0, $v0, $zero
		bne $t0, $0, opcao_errada
		li $t0, 3
		slt $t0, $v0, $t0
		beq $t0, $zero, opcao_errada
		
  		move $a0, $v0
  		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal borra_imagem
  		lw $ra, 0($sp)
  		addi $sp, $sp, 4
  		jr $ra
  	nao_borramento:
  	bne $t1, $v0, nao_extracao
  	
  	la $a0, mensagem_menu1_2
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
	slt $t0, $v0, $zero
	bne $t0, $0, opcao_errada
	li $t0, 5
	slt $t0, $v0, $t0
	beq $t0, $zero, opcao_errada
	
	move $t0, $v0
	la $a0, mensagem_menu1_2_1
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
	slt $t1, $v0, $zero
	bne $t1, $0, opcao_errada
	li $t1, 256
	slt $t1, $v0, $t1
	beq $t1, $zero, opcao_errada
	
	move $a1, $v0
  	la $a0, mensagem_menu1_2_2
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
	slt $t1, $v0, $zero
	bne $t1, $0, opcao_errada
	li $t1, 256
	slt $t1, $v0, $t1
	beq $t1, $zero, opcao_errada
	
	move $a2, $v0
	la $a0, mensagem_menu1_2_3
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
	slt $t1, $v0, $zero
	bne $t1, $0, opcao_errada
	li $t1, 256
	slt $t1, $v0, $t1
	beq $t1, $zero, opcao_errada
	
	move $a3, $v0
	move $a0, $t0
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal Edge_Extractor
  	lw $ra, 0($sp)
  	addi $sp, $sp, 4
  	jr $ra
  	
	nao_extracao:
	bne $t2, $v0, opcao_errada
		la $a0, mensagem_menu1_3
		li $v0, 4
		syscall
		li $v0, 5
		syscall
		
		slt $t0, $v0, $zero
		bne $t0, $0, opcao_errada
		li $t0, 5
		slt $t0, $v0, $t0
		beq $t0, $zero, opcao_errada
		
  		move $a0, $v0
  		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal rafael
  		lw $ra, 0($sp)
  		addi $sp, $sp, 4
  		jr $ra
	
	opcao_errada:
	la $a0, mensagem_menu2
	li $v0, 4
	syscall
	j menu

####################################################################################################################################
#Ana Carolina
Edge_Extractor: # Funcao recebe em $a0 o tipo de mascara, em $a1, $a2, $a3 as intencidades RGB dos pixels da mascara respectivamente

	#Empilhando todos os registradores salvos (Lembrar de desempilhar no final)
	addi $sp, $sp, -32
	sw $s0, 0($sp)
	sw $s1, 4($sp)	
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)

	move $s0, $s1 # $s0 = tamanho da imagem bytes
	move $s1, $s3 # $s1 = largura da imagem em pixels
	move $s2, $s4 # $s1 = altura da imagem em pixels
	
	la $s3, vetorEdge0
	la $s4, vetorEdge1
	la $s5, vetorEdge2
	
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	move $a0, $fp
	move $a1, $s0
	jal show_original_image
	lw $a1, 8($sp)
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	
	#preparando contadores da matriz
	move $t1, $0 #i
	move $t2, $0 #j
	addi $t3, $s1, -1 #Largura da imagem menos 1

	la $s7, pixel_image
	
	li $t9, 4
	beq $a0, $t9, Bquadrado 
	addi $t9, $t9, -1
	beq $a0, $t9, Bcruz
	addi $t9, $t9, -1
	beq $a0, $t9, Bvertical
#################################################################################################################################
Bhorizontal:
	
	Loop1_Bhorizontal:
		beq $t1, $s2, exit_loop1_Bhorizontal #Compara linhas (altura)
		la $s6, buffer_extractor
		Loop2_Bhorizontal:
			beq $t2, $s1, exit_loop2_Bhorizontal #Compara colunas (largura)
			
			bne $t2, $zero, nao_primeiro #Verifica se e o primeiro bit da linha
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura
			mul $t4, $t4, 4
			# add $t4, $t4, $t2 nao e necessÃ¡rio pois $t2==0
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_horizontal
			move $t4, $0
			nao_negativo1_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_horizontal
			move $t4, $0
			nao_negativo2_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_horizontal
			move $t4, $0
			nao_negativo3_horizontal: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_horizontal
			move $t4, $0
			nao_negativo12_horizontal: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_horizontal
			move $t4, $0
			nao_negativo22_horizontal: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo32_horizontal
			move $t4, $0
			nao_negativo32_horizontal: sb $t4, 2($s5)
			
			########################################################################################
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal

			nao_primeiro:
			bne $t2, $t3, nao_ultimo #Verifica se o ultimo bit da linha
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_horizontal
			move $t4, $0
			nao_negativo4_horizontal: sb $t4, 0($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_horizontal
			move $t4, $0
			nao_negativo5_horizontal: sb $t4, 0($s4)
			
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_horizontal
			move $t4, $0
			nao_negativo6_horizontal: sb $t4, 0($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo41_horizontal
			move $t4, $0
			nao_negativo41_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo51_horizontal
			move $t4, $0
			nao_negativo51_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo61_horizontal
			move $t4, $0
			nao_negativo61_horizontal: sb $t4, 1($s5)
			
			 ########################################################################################## 
			 
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
		
			j Loop2_Bhorizontal

			nao_ultimo:
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			
			addi $t5, $t5, -4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_horizontal
			move $t4, $0
			nao_negativo7_horizontal: sb $t4, 0($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_horizontal
			move $t4, $0
			nao_negativo8_horizontal: sb $t4, 0($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_horizontal
			move $t4, $0
			nao_negativo9_horizontal: sb $t4, 0($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo71_horizontal
			move $t4, $0
			nao_negativo71_horizontal: sb $t4, 1($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo81_horizontal
			move $t4, $0
			nao_negativo81_horizontal: sb $t4, 1($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo91_horizontal
			move $t4, $0
			nao_negativo91_horizontal: sb $t4, 1($s5)
			
			 ########################################################################################## 
			 
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_horizontal
			move $t4, $0
			nao_negativo72_horizontal: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_horizontal
			move $t4, $0
			nao_negativo82_horizontal: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_horizontal
			move $t4, $0
			nao_negativo92_horizontal: sb $t4, 2($s5)
			
			#######################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal
	
		exit_loop2_Bhorizontal:

			li $t5, 0x10040000
			mul $t4, $t1, $s1 #linha vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4

			move $t6, $0
			la $t7, buffer_extractor
		loop_carrega_linha:
			beq $t6, $s1, exit_loop_carrega_linha
			lw $t8, 0($t7)
			sw $t8, 0($t5)
			addi $t5, $t5, 4
			addi $t7, $t7, 4
			addi $t6, $t6, 1
			j loop_carrega_linha
		exit_loop_carrega_linha:
			move $t2, $0
			addi $t1, $t1, 1
					
			j Loop1_Bhorizontal
	
	exit_loop1_Bhorizontal:
	
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor

#####################################################################################################################################
Bvertical:
	
	Loop1_Bvertical:
		beq $t1, $s2, exit_loop1_Bvertical #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, par
		la $s6, buffer_extractor
		j Loop2_Bvertical
		par:
		la $s6, buffer_extractor2
		
		Loop2_Bvertical:
			beq $t2, $s1, exit_loop2_Bvertical #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha #Verifica se e o primeiro bit da linha
			
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			# mul $t4, $t1, $s1 #linha vezes largura nao precisa pois $t1==0
			add $t4, $0, $t2 
			mul $t4, $t4, 4
			
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_vertical
			move $t4, $0
			nao_negativo1_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_vertical
			move $t4, $0
			nao_negativo2_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_vertical
			move $t4, $0
			nao_negativo3_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			mul $t4, $s1, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_vertical
			move $t4, $0
			nao_negativo11_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_vertical
			move $t4, $0
			nao_negativo21_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo31_vertical
			move $t4, $0
			nao_negativo31_vertical: sb $t4, 2($s5)
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			j Loop2_Bvertical
			
			nao_primeira_linha:
			bne $t1, $t3, nao_ultima_linha #Verifica se o ultimo bit da linha
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $t1, $s1 #linha vezes largura nao precisa pois $t1==0
			add $t4, $t4, $t2 
			mul $t4, $t4, 4
			
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_vertical
			move $t4, $0
			nao_negativo4_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_vertical
			move $t4, $0
			nao_negativo5_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_vertical
			move $t4, $0
			nao_negativo6_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			mul $t4, $s1, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo41_vertical
			move $t4, $0
			nao_negativo41_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo51_vertical
			move $t4, $0
			nao_negativo51_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo61_vertical
			move $t4, $0
			nao_negativo61_vertical: sb $t4, 2($s5)
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			j Loop2_Bvertical
		
	
			nao_ultima_linha:
			
			mul $t4, $t1, $s1 #linha vezes largura
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			
			li $t5, 0x10040000
			add $t5, $t5, $t4 #prepara o endereÃ§o do pixel na memoria heap
			
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_vertical
			move $t4, $0
			nao_negativo7_vertical: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_vertical
			move $t4, $0
			nao_negativo8_vertical: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_vertical
			move $t4, $0
			nao_negativo9_vertical: sb $t4, 1($s5)
			 
			######################################################################################## 
			mul $t4, $s1, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo71_vertical
			move $t4, $0
			nao_negativo71_vertical: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo81_vertical
			move $t4, $0
			nao_negativo81_vertical: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo91_vertical
			move $t4, $0
			nao_negativo91_vertical: sb $t4, 0($s5)
			
			 ########################################################################################## 
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_vertical
			move $t4, $0
			nao_negativo72_vertical: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_vertical
			move $t4, $0
			nao_negativo82_vertical: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_vertical
			move $t4, $0
			nao_negativo92_vertical: sb $t4, 2($s5)
			
			#######################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 3
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
		
			addi $t2, $t2, 1
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			j Loop2_Bhorizontal
	
		exit_loop2_Bvertical:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_vertical
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bvertical
			
			carrega_pixel_vertical:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4

			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_vertical:
				beq $t6, $s1, exit_loop_carrega_linha_vertical
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical
			exit_loop_carrega_linha_vertical:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bvertical
			
			parload:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_vertical2:
				beq $t6, $s1, exit_loop_carrega_linha_vertical2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical2
			exit_loop_carrega_linha_vertical2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bvertical
	
	exit_loop1_Bvertical:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_vertical_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_vertical_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical_ultimalinha
			exit_loop_carrega_linha_vertical_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bvertical
			
			parload_ultimalinha:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_vertical2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bvertical
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_vertical2_ultimalinha
	
		exit2_loop1_Bvertical:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor
	

###################################################################################################################################
Bcruz:
	
	Loop1_Bcruz:
		beq $t1, $s2, exit_loop1_Bcruz #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, parcruz
		la $s6, buffer_extractor
		j Loop2_Bcruz
		parcruz:
		la $s6, buffer_extractor2
		
		Loop2_Bcruz:
			beq $t2, $s1, exit_loop2_Bcruz #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha_cruz #Verifica se primeira linha		

			bne $t2, $zero, nao_primeira_coluna_cruz
				
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 3($s3)
			sb $t4, 0($s4)
			sb $t4, 3($s4)
			sb $t4, 0($s5)
			sb $t4, 3($s5)
			
			li $t5, 0x10040000
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_cruz
			move $t4, $0
			nao_negativo1_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_cruz
			move $t4, $0
			nao_negativo2_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_cruz
			move $t4, $0
			nao_negativo3_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_cruz
			move $t4, $0
			nao_negativo12_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_cruz
			move $t4, $0
			nao_negativo22_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo32_cruz
			move $t4, $0
			nao_negativo32_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_cruz
			move $t4, $0
			nao_negativo13_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_cruz
			move $t4, $0
			nao_negativo23_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo33_cruz
			move $t4, $0
			nao_negativo33_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
				
			nao_primeira_coluna_cruz:
			bne $t2, $t3, nao_ultima_coluna_cruz
			
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_cruz
			move $t4, $0
			nao_negativo4_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_cruz
			move $t4, $0
			nao_negativo5_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_cruz
			move $t4, $0
			nao_negativo6_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo42_cruz
			move $t4, $0
			nao_negativo42_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo52_cruz
			move $t4, $0
			nao_negativo52_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo62_cruz
			move $t4, $0
			nao_negativo62_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo43_cruz
			move $t4, $0
			nao_negativo43_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo53_cruz
			move $t4, $0
			nao_negativo53_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo63_cruz
			move $t4, $0
			nao_negativo63_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			
			nao_ultima_coluna_cruz:
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_cruz
			move $t4, $0
			nao_negativo7_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_cruz
			move $t4, $0
			nao_negativo8_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_cruz
			move $t4, $0
			nao_negativo9_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo72_cruz
			move $t4, $0
			nao_negativo72_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo82_cruz
			move $t4, $0
			nao_negativo82_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo92_cruz
			move $t4, $0
			nao_negativo92_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo73_cruz
			move $t4, $0
			nao_negativo73_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo83_cruz
			move $t4, $0
			nao_negativo83_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo93_cruz
			move $t4, $0
			nao_negativo93_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo74_cruz
			move $t4, $0
			nao_negativo74_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo84_cruz
			move $t4, $0
			nao_negativo84_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo94_cruz
			move $t4, $0
			nao_negativo94_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz
                        #########################################################################################
			
			nao_primeira_linha_cruz:
			bne $t1, $t3, nao_ultima_linha_cruz 
			#############################################################################
			bne $t2, $zero, nao_primeira_coluna_cruz2
				
				
					
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 3($s3)
			sb $t4, 2($s4)
			sb $t4, 3($s4)
			sb $t4, 2($s5)
			sb $t4, 3($s5)
		
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_10_cruz
			move $t4, $0
			nao_negativo_10_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_11_cruz
			move $t4, $0
			nao_negativo_11_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_12_cruz
			move $t4, $0
			nao_negativo_12_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo102_cruz
			move $t4, $0
			nao_negativo102_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo112_cruz
			move $t4, $0
			nao_negativo112_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo122_cruz
			move $t4, $0
			nao_negativo122_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo103_cruz
			move $t4, $0
			nao_negativo103_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo113_cruz
			move $t4, $0
			nao_negativo113_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo123_cruz
			move $t4, $0
			nao_negativo123_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			nao_primeira_coluna_cruz2:
			bne $t2, $t3, nao_ultima_coluna_cruz2
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 4($s3)
			sb $t4, 2($s4)
			sb $t4, 4($s4)
			sb $t4, 2($s5)
			sb $t4, 4($s5)
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_13_cruz
			move $t4, $0
			nao_negativo_13_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_14_cruz
			move $t4, $0
			nao_negativo_14_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_15_cruz
			move $t4, $0
			nao_negativo_15_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo132_cruz
			move $t4, $0
			nao_negativo132_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo142_cruz
			move $t4, $0
			nao_negativo142_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo152_cruz
			move $t4, $0
			nao_negativo152_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo133_cruz
			move $t4, $0
			nao_negativo133_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo143_cruz
			move $t4, $0
			nao_negativo143_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo153_cruz
			move $t4, $0
			nao_negativo153_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz	

			nao_ultima_coluna_cruz2:
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_cruz
			move $t4, $0
			nao_negativo16_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_cruz
			move $t4, $0
			nao_negativo17_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_cruz
			move $t4, $0
			nao_negativo18_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo162_cruz
			move $t4, $0
			nao_negativo162_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo172_cruz
			move $t4, $0
			nao_negativo172_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo182_cruz
			move $t4, $0
			nao_negativo182_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo163_cruz
			move $t4, $0
			nao_negativo163_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo173_cruz
			move $t4, $0
			nao_negativo173_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo183_cruz
			move $t4, $0
			nao_negativo183_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo164_cruz
			move $t4, $0
			nao_negativo164_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo174_cruz
			move $t4, $0
			nao_negativo174_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo184_cruz
			move $t4, $0
			nao_negativo184_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz

			
			############################################################################
			nao_ultima_linha_cruz:

			bne $t2, $zero, nao_primeira_coluna_cruz3
			
			li $t4, 255
			
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			
			li $t5, 0x10040000
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_cruz
			move $t4, $0
			nao_negativo19_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_cruz
			move $t4, $0
			nao_negativo20_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_cruz
			move $t4, $0
			nao_negativo21_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo192_cruz
			move $t4, $0
			nao_negativo192_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo202_cruz
			move $t4, $0
			nao_negativo202_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo212_cruz
			move $t4, $0
			nao_negativo212_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo193_cruz
			move $t4, $0
			nao_negativo193_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo203_cruz
			move $t4, $0
			nao_negativo203_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo213_cruz
			move $t4, $0
			nao_negativo213_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo194_cruz
			move $t4, $0
			nao_negativo194_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo204_cruz
			move $t4, $0
			nao_negativo204_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo214_cruz
			move $t4, $0
			nao_negativo214_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz

			nao_primeira_coluna_cruz3:
			bne $t2, $t3, nao_ultima_coluna_cruz3
		
			li $t4, 255
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_22_cruz
			move $t4, $0
			nao_negativo_22_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_23_cruz
			move $t4, $0
			nao_negativo_23_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_24_cruz
			move $t4, $0
			nao_negativo_24_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo222_cruz
			move $t4, $0
			nao_negativo222_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo232_cruz
			move $t4, $0
			nao_negativo232_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo242_cruz
			move $t4, $0
			nao_negativo242_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo223_cruz
			move $t4, $0
			nao_negativo223_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo233_cruz
			move $t4, $0
			nao_negativo233_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo243_cruz
			move $t4, $0
			nao_negativo243_cruz: sb $t4, 0($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo224_cruz
			move $t4, $0
			nao_negativo224_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo234_cruz
			move $t4, $0
			nao_negativo234_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo244_cruz
			move $t4, $0
			nao_negativo244_cruz: sb $t4, 2($s5)
			
			########################################################################################
		
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bcruz	
				
											
			nao_ultima_coluna_cruz3:
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_cruz
			move $t4, $0
			nao_negativo25_cruz: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_cruz
			move $t4, $0
			nao_negativo26_cruz: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_cruz
			move $t4, $0
			nao_negativo27_cruz: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo252_cruz
			move $t4, $0
			nao_negativo252_cruz: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo262_cruz
			move $t4, $0
			nao_negativo262_cruz: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo272_cruz
			move $t4, $0
			nao_negativo272_cruz: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo253_cruz
			move $t4, $0
			nao_negativo253_cruz: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo263_cruz
			move $t4, $0
			nao_negativo263_cruz: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo273_cruz
			move $t4, $0
			nao_negativo273_cruz: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo254_cruz
			move $t4, $0
			nao_negativo254_cruz: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo264_cruz
			move $t4, $0
			nao_negativo264_cruz: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo274_cruz
			move $t4, $0
			nao_negativo274_cruz: sb $t4, 0($s5)
			
			########################################################################################
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo255_cruz
			move $t4, $0
			nao_negativo255_cruz: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo265_cruz
			move $t4, $0
			nao_negativo265_cruz: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo275_cruz
			move $t4, $0
			nao_negativo275_cruz: sb $t4, 2($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)

			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 5
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bcruz
			
			############################################################################
			
	exit_loop2_Bcruz:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_cruz
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bcruz
			
			carrega_pixel_cruz:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_cruz
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_cruz:
				beq $t6, $s1, exit_loop_carrega_linha_cruz
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz
			exit_loop_carrega_linha_cruz:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bcruz
			
			parload_cruz:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_cruz2:
				beq $t6, $s1, exit_loop_carrega_linha_cruz2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz2
			exit_loop_carrega_linha_cruz2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bcruz

	exit_loop1_Bcruz:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha_cruz
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_cruz_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_cruz_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz_ultimalinha
			exit_loop_carrega_linha_cruz_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bcruz
			
			parload_ultimalinha_cruz:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4

				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_cruz2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bcruz
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_cruz2_ultimalinha

		exit2_loop1_Bcruz:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor
	

#########################################################################################################################################
Bquadrado:
	
	Loop1_Bquadrado:
		beq $t1, $s2, exit_loop1_Bquadrado #Compara linhas (altura)
		li $t4, 2
		div $t1, $t4
		mfhi $t4
		beq $t4, $zero, parquadrado
		la $s6, buffer_extractor
		j Loop2_Bquadrado
		parquadrado:
		la $s6, buffer_extractor2
		
		Loop2_Bquadrado:
			beq $t2, $s1, exit_loop2_Bquadrado #Compara colunas (largura)
			
			bne $t1, $zero, nao_primeira_linha_quadrado #Verifica se primeira linha		

                       #######################################################################################
			bne $t2, $zero, nao_primeira_coluna_quadrado
				
			li $t4, 255	
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			
			
			li $t5, 0x10040000
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_quadrado
			move $t4, $0
			nao_negativo1_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_quadrado
			move $t4, $0
			nao_negativo2_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_quadrado
			move $t4, $0
			nao_negativo3_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_2_quadrado
			move $t4, $0
			nao_negativo1_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_2_quadrado
			move $t4, $0
			nao_negativo2_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_2_quadrado
			move $t4, $0
			nao_negativo3_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_3_quadrado
			move $t4, $0
			nao_negativo1_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_3_quadrado
			move $t4, $0
			nao_negativo2_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_3_quadrado
			move $t4, $0
			nao_negativo3_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo1_4_quadrado
			move $t4, $0
			nao_negativo1_4_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo2_4_quadrado
			move $t4, $0
			nao_negativo2_4_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo3_4_quadrado
			move $t4, $0
			nao_negativo3_4_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
				
			nao_primeira_coluna_quadrado:
			bne $t2, $t3, nao_ultima_coluna_quadrado
			
			li $t4, 255	
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_quadrado
			move $t4, $0
			nao_negativo4_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_quadrado
			move $t4, $0
			nao_negativo5_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_quadrado
			move $t4, $0
			nao_negativo6_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_2_quadrado
			move $t4, $0
			nao_negativo4_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_2_quadrado
			move $t4, $0
			nao_negativo5_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_2_quadrado
			move $t4, $0
			nao_negativo6_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_3_quadrado
			move $t4, $0
			nao_negativo4_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_3_quadrado
			move $t4, $0
			nao_negativo5_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_3_quadrado
			move $t4, $0
			nao_negativo6_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo4_4_quadrado
			move $t4, $0
			nao_negativo4_4_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo5_4_quadrado
			move $t4, $0
			nao_negativo5_4_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo6_4_quadrado
			move $t4, $0
			nao_negativo6_4_quadrado: sb $t4, 7($s5)
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			
			nao_ultima_coluna_quadrado:
			
			li $t4, 255
			sb $t4, 0($s3)
			sb $t4, 0($s4)
			sb $t4, 0($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			
			
			
			mul $t4, $t2, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_quadrado
			move $t4, $0
			nao_negativo7_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_quadrado
			move $t4, $0
			nao_negativo8_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_quadrado
			move $t4, $0
			nao_negativo9_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_2_quadrado
			move $t4, $0
			nao_negativo7_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_2_quadrado
			move $t4, $0
			nao_negativo8_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_2_quadrado
			move $t4, $0
			nao_negativo9_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_3_quadrado
			move $t4, $0
			nao_negativo7_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_3_quadrado
			move $t4, $0
			nao_negativo8_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_3_quadrado
			move $t4, $0
			nao_negativo9_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_4_quadrado
			move $t4, $0
			nao_negativo7_4_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_4_quadrado
			move $t4, $0
			nao_negativo8_4_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_4_quadrado
			move $t4, $0
			nao_negativo9_4_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_5_quadrado
			move $t4, $0
			nao_negativo7_5_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_5_quadrado
			move $t4, $0
			nao_negativo8_5_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_5_quadrado
			move $t4, $0
			nao_negativo9_5_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo7_6_quadrado
			move $t4, $0
			nao_negativo7_6_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo8_6_quadrado
			move $t4, $0
			nao_negativo8_6_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo9_6_quadrado
			move $t4, $0
			nao_negativo9_6_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado
                        #########################################################################################
			
			nao_primeira_linha_quadrado:
			bne $t1, $t3, nao_ultima_linha_quadrado 
			
			bne $t2, $zero, nao_primeira_coluna_quadrado2
	
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			
			
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_10_quadrado
			move $t4, $0
			nao_negativo_10_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_11_quadrado
			move $t4, $0
			nao_negativo_11_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_12_quadrado
			move $t4, $0
			nao_negativo_12_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_2_quadrado
			move $t4, $0
			nao_negativo10_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_2_quadrado
			move $t4, $0
			nao_negativo11_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_2_quadrado
			move $t4, $0
			nao_negativo12_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_3_quadrado
			move $t4, $0
			nao_negativo10_3_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_3_quadrado
			move $t4, $0
			nao_negativo11_3_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_3_quadrado
			move $t4, $0
			nao_negativo12_3_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo10_4_quadrado
			move $t4, $0
			nao_negativo10_4_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo11_4_quadrado
			move $t4, $0
			nao_negativo11_4_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo12_4_quadrado
			move $t4, $0
			nao_negativo12_4_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			nao_primeira_coluna_quadrado2:
			bne $t2, $t3, nao_ultima_coluna_quadrado2
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_13_quadraddo
			move $t4, $0
			nao_negativo_13_quadraddo: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_14_quadraddo
			move $t4, $0
			nao_negativo_14_quadraddo: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_15_quadraddo
			move $t4, $0
			nao_negativo_15_quadraddo: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_2_quadrado
			move $t4, $0
			nao_negativo13_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_2_quadrado
			move $t4, $0
			nao_negativo14_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_2_quadrado
			move $t4, $0
			nao_negativo15_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_3_quadraddo
			move $t4, $0
			nao_negativo13_3_quadraddo: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_3_quadraddo
			move $t4, $0
			nao_negativo14_3_quadraddo: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_3_quadraddo
			move $t4, $0
			nao_negativo15_3_quadraddo: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo13_4_quadraddo
			move $t4, $0
			nao_negativo13_4_quadraddo: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo14_4_quadraddo
			move $t4, $0
			nao_negativo14_4_quadraddo: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo15_4_quadraddo
			move $t4, $0
			nao_negativo15_4_quadraddo: sb $t4, 5($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado	

			nao_ultima_coluna_quadrado2:
			
			li $t4, 255
			sb $t4, 2($s3)
			sb $t4, 2($s4)
			sb $t4, 2($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_quadrado
			move $t4, $0
			nao_negativo16_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_quadrado
			move $t4, $0
			nao_negativo17_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_quadrado
			move $t4, $0
			nao_negativo18_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_2_quadrado
			move $t4, $0
			nao_negativo16_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_2_quadrado
			move $t4, $0
			nao_negativo17_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_2_quadrado
			move $t4, $0
			nao_negativo18_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_3_quadrado
			move $t4, $0
			nao_negativo16_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_3_quadrado
			move $t4, $0
			nao_negativo17_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_3_quadrado
			move $t4, $0
			nao_negativo18_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_4_quadrado
			move $t4, $0
			nao_negativo16_4_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_4_quadrado
			move $t4, $0
			nao_negativo17_4_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_4_quadrado
			move $t4, $0
			nao_negativo18_4_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_5_quadrado
			move $t4, $0
			nao_negativo16_5_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_5_quadrado
			move $t4, $0
			nao_negativo17_5_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_5_quadrado
			move $t4, $0
			nao_negativo18_5_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo16_6_quadrado
			move $t4, $0
			nao_negativo16_6_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo17_6_quadrado
			move $t4, $0
			nao_negativo17_6_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo18_6_quadrado
			move $t4, $0
			nao_negativo18_6_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado

			############################################################################
			nao_ultima_linha_quadrado:
			
			bne $t2, $zero, nao_primeira_coluna_quadrado3
			
			li $t4, 255
			
			sb $t4, 3($s3)
			sb $t4, 3($s4)
			sb $t4, 3($s5)
			sb $t4, 5($s3)
			sb $t4, 5($s4)
			sb $t4, 5($s5)
			sb $t4, 7($s3)
			sb $t4, 7($s4)
			sb $t4, 7($s5)

			li $t5, 0x10040000
			mul $t4, $s1, $t1
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_quadrado
			move $t4, $0
			nao_negativo19_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_quadrado
			move $t4, $0
			nao_negativo20_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_quadrado
			move $t4, $0
			nao_negativo21_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_2_quadrado
			move $t4, $0
			nao_negativo19_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_2_quadrado
			move $t4, $0
			nao_negativo20_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_2_quadrado
			move $t4, $0
			nao_negativo21_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, -4
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_3_quadrado
			move $t4, $0
			nao_negativo19_3_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_3_quadrado
			move $t4, $0
			nao_negativo20_3_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_3_quadrado
			move $t4, $0
			nao_negativo21_3_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_4_quadrado
			move $t4, $0
			nao_negativo19_4_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_4_quadrado
			move $t4, $0
			nao_negativo20_4_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_4_quadrado
			move $t4, $0
			nao_negativo21_4_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_5_quadrado
			move $t4, $0
			nao_negativo19_5_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_5_quadrado
			move $t4, $0
			nao_negativo20_5_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_5_quadrado
			move $t4, $0
			nao_negativo21_5_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo19_6_quadrado
			move $t4, $0
			nao_negativo19_6_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo20_6_quadrado
			move $t4, $0
			nao_negativo20_6_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo21_6_quadrado
			move $t4, $0
			nao_negativo21_6_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20
			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado

			nao_primeira_coluna_quadrado3:
			bne $t2, $t3, nao_ultima_coluna_quadrado3
		
			li $t4, 255
			sb $t4, 4($s3)
			sb $t4, 4($s4)
			sb $t4, 4($s5)
			sb $t4, 6($s3)
			sb $t4, 6($s4)
			sb $t4, 6($s5)
			sb $t4, 8($s3)
			sb $t4, 8($s4)
			sb $t4, 8($s5)
			
			
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)	
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_22_quadrado
			move $t4, $0
			nao_negativo_22_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_23_quadrado
			move $t4, $0
			nao_negativo_23_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo_24_quadrado
			move $t4, $0
			nao_negativo_24_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_2_quadrado
			move $t4, $0
			nao_negativo22_2_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_2_quadrado
			move $t4, $0
			nao_negativo23_2_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_2_quadrado
			move $t4, $0
			nao_negativo24_2_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_3_quadrado
			move $t4, $0
			nao_negativo22_3_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_3_quadrado
			move $t4, $0
			nao_negativo23_3_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_3_quadrado
			move $t4, $0
			nao_negativo24_3_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_4_quadrado
			move $t4, $0
			nao_negativo22_4_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_4_quadrado
			move $t4, $0
			nao_negativo23_4_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_4_quadrado
			move $t4, $0
			nao_negativo24_4_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_5_quadrado
			move $t4, $0
			nao_negativo22_5_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_5_quadrado
			move $t4, $0
			nao_negativo23_5_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_5_quadrado
			move $t4, $0
			nao_negativo24_5_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, -4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo22_6_quadrado
			move $t4, $0
			nao_negativo22_6_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo23_6_quadrado
			move $t4, $0
			nao_negativo23_6_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo24_6_quadrado
			move $t4, $0
			nao_negativo24_6_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			
			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			
			addi $t2, $t2, 1
			j Loop2_Bquadrado	
				
											
			nao_ultima_coluna_quadrado3:
		
			mul $t4, $s1, $t1
			add $t4, $t4, $t2
			mul $t4, $t4, 4
			li $t5, 0x10040000
			add $t5, $t5, $t4
			
			lw $t4, 0($t5) #captura o pixel da imagem na memoria heap
			sw $t4, 0($s7)
			
			#####################################################################################
			
			lbu $t4, 2($s7) #subtraido o valor R do elemento estruturante do byte R do pixel_image
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_quadrado
			move $t4, $0
			nao_negativo25_quadrado: sb $t4, 1($s3)
			
			lbu $t4, 1($s7) #subtraido o valor G do elemento estruturante do byte G do pixel_image
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_quadrado
			move $t4, $0
			nao_negativo26_quadrado: sb $t4, 1($s4)
			
			lbu $t4, 0($s7) #subtraido o valor B do elemento estruturante do byte B do pixel_image
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_quadrado
			move $t4, $0
			nao_negativo27_quadrado: sb $t4, 1($s5)
			 
			######################################################################################## 
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_2_quadrado
			move $t4, $0
			nao_negativo25_2_quadrado: sb $t4, 4($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_2_quadrado
			move $t4, $0
			nao_negativo26_2_quadrado: sb $t4, 4($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_2_quadrado
			move $t4, $0
			nao_negativo27_2_quadrado: sb $t4, 4($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_3_quadrado
			move $t4, $0
			nao_negativo25_3_quadrado: sb $t4, 3($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_3_quadrado
			move $t4, $0
			nao_negativo26_3_quadrado: sb $t4, 3($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_3_quadrado
			move $t4, $0
			nao_negativo27_3_quadrado: sb $t4, 3($s5)
			
			########################################################################################
			
			
			mul $t4, $s1, 4
			addi $t5, $t5, 4
			sub $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_4_quadrado
			move $t4, $0
			nao_negativo25_4_quadrado: sb $t4, 0($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_4_quadrado
			move $t4, $0
			nao_negativo26_4_quadrado: sb $t4, 0($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_4_quadrado
			move $t4, $0
			nao_negativo27_4_quadrado: sb $t4, 0($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_5_quadrado
			move $t4, $0
			nao_negativo25_5_quadrado: sb $t4, 6($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_5_quadrado
			move $t4, $0
			nao_negativo26_5_quadrado: sb $t4, 6($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_5_quadrado
			move $t4, $0
			nao_negativo27_5_quadrado: sb $t4, 6($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_6_quadrado
			move $t4, $0
			nao_negativo25_6_quadrado: sb $t4, 5($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_6_quadrado
			move $t4, $0
			nao_negativo26_6_quadrado: sb $t4, 5($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_6_quadrado
			move $t4, $0
			nao_negativo27_6_quadrado: sb $t4, 5($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			mul $t4, $s1, 4
			mul $t4, $t4, 2
			add $t5, $t5, $t4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_7_quadrado
			move $t4, $0
			nao_negativo25_7_quadrado: sb $t4, 2($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_7_quadrado
			move $t4, $0
			nao_negativo26_7_quadrado: sb $t4, 2($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_7_quadrado
			move $t4, $0
			nao_negativo27_7_quadrado: sb $t4, 2($s5)
			
			########################################################################################
			
			addi $t5, $t5, 4
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_8_quadrado
			move $t4, $0
			nao_negativo25_8_quadrado: sb $t4, 8($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_8_quadrado
			move $t4, $0
			nao_negativo26_8_quadrado: sb $t4, 8($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_8_quadrado
			move $t4, $0
			nao_negativo27_8_quadrado: sb $t4, 8($s5)
			
			########################################################################################
			
			addi $t5, $t5, -8
			lw $t4, 0($t5)
			sw $t4, 0($s7)
			
			lbu $t4, 2($s7)
			sub $t4, $t4, $a1
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo25_9_quadrado
			move $t4, $0
			nao_negativo25_9_quadrado: sb $t4, 7($s3)
			
			lbu $t4, 1($s7)
			sub $t4, $t4, $a2
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo26_9_quadrado
			move $t4, $0
			nao_negativo26_9_quadrado: sb $t4, 7($s4)
			
			lbu $t4, 0($s7)
			sub $t4, $t4, $a3
			slt $t9, $t4, $zero
			beq $t9, $0, nao_negativo27_9_quadrado
			move $t4, $0
			nao_negativo27_9_quadrado: sb $t4, 7($s5)
			
			########################################################################################
			
			
			#Chamando a funcao minimiza os valores dos vetores RGB
			addi $sp, $sp, -20
			sw $ra, 0($sp)
			sw $a0, 4($sp)
			sw $a1, 8($sp)
			sw $a2, 12($sp)
			sw $a3, 16($sp)
			
			addi $sp, $sp, -12 #Empilhando os contadores
			sw $t1, 0($sp)
			sw $t2, 4($sp)
			sw $t3, 8($sp)
			
			
			move $a0, $s3
			move $a1, $s4
			move $a2, $s5
			li $a3, 9
			jal minimiza
			
			lw $t3, 8($sp)
			lw $t2, 4($sp)
			lw $t1, 0($sp)
			addi $sp, $sp, 12
			
			
			lw $a3, 16($sp)
			lw $a2, 12($sp)
			lw $a1, 8($sp)
			lw $a0, 4($sp)
			lw $ra, 0($sp)
			addi $sp, $sp, 20

			la $t5, result
			lw $t6, 0($t5)
			sw $t6, 0($s6)
			addi $s6, $s6, 4
			addi $t2, $t2, 1
			j Loop2_Bquadrado
			
			############################################################################
			
	exit_loop2_Bquadrado:
			
			slti $t4, $t1, 1
			beq $t4, $zero, carrega_pixel_quadrado
			move $t2, $0
			addi $t1, $t1, 1	
			j Loop1_Bquadrado
			
			carrega_pixel_quadrado:
			
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_quadrado
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_quadrado:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado
			exit_loop_carrega_linha_quadrado:
				move $t2, $0
				addi $t1, $t1, 1
				j Loop1_Bcruz
			
			parload_quadrado:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_quadrado2:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado2
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado2
			exit_loop_carrega_linha_quadrado2:
				move $t2, $0
				addi $t1, $t1, 1
					
				j Loop1_Bquadrado
					
	exit_loop1_Bquadrado:
	
			li $t4, 2
			div $t1, $t4
			mfhi $t4
			beq $t4, $zero, parload_ultimalinha_quadrado
			li $t5, 0x10040000
			addi $t4, $t1, -1
			mul $t4, $t4, $s1 #linha menos 1 vezes largura
			mul $t4, $t4, 4
			add $t5, $t5, $t4	
			move $t6, $0
			la $t7, buffer_extractor
			loop_carrega_linha_quadrado_ultimalinha:
				beq $t6, $s1, exit_loop_carrega_linha_quadrado_ultimalinha
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado_ultimalinha
			exit_loop_carrega_linha_quadrado_ultimalinha:
				move $t2, $0
				addi $t1, $t1, 1
				j exit2_loop1_Bquadrado
			
			parload_ultimalinha_quadrado:
				li $t5, 0x10040000
				addi $t4, $t1, -1
				mul $t4, $t4, $s1 #linha menos 1 vezes largura
				mul $t4, $t4, 4
				add $t5, $t5, $t4
				move $t6, $0
				la $t7, buffer_extractor2
			loop_carrega_linha_quadrado2_ultimalinha:
				beq $t6, $s1, exit2_loop1_Bquadrado
				lw $t8, 0($t7)
				sw $t8, 0($t5)
				addi $t5, $t5, 4
				addi $t7, $t7, 4
				addi $t6, $t6, 1
				j loop_carrega_linha_quadrado2_ultimalinha
		
		exit2_loop1_Bquadrado:
		lw $s7, 28($sp)
		lw $s6, 24($sp)
		lw $s5, 20($sp)
		lw $s4, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)	
		lw $s0, 0($sp)
		addi $sp, $sp, 32
	
		j Exit_Edge_Extractor

		
Exit_Edge_Extractor:

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a0, $fp
	move $a1, $s1 #tamanho da imagem em bytes(ja foi restaurado da pilha)
	jal Edge_detector
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
###########################################################################################################################################
						
Edge_detector: # Funcao que recebe como parametros: 1) O endereÃ§o de delimitador $fp da pila onde se encontra a imagem original em $a0
#2) o tamanho da imagem em bytes em $a1. Esta funcao carrega a imagem original na memoria heap para ser mostrada no bitmap display
	
	move $t0, $a0
	
	#Soma o endereÃ§o de base da memoria heap com o tamanho da imagem original (abre espaÃ§o na memoria heap)
	li $t1, 0x10040000
	div $t2, $a1, 3
	add $t2, $t2, $a1
	add $t1, $t1, $t2
	move $t2, $zero
	Loop_edge_detector: #Loop que desempilha os pixels de tras pra frente e ja carrega na posicao correta na memoria heap
		beq $t2, $a1, exit_edge_detector
		lw $t3, 0($t0)
		lw $t4, 0($t1)
		sub $t3, $t3, $t4
		sw $t3, 0($t1)
		addi $t0, $t0, 4
		addi $t1, $t1, -4
		addi $t2, $t2, 3
		j Loop_edge_detector
exit_edge_detector:
		jr $ra

######################################################################################################################################
minimiza: #Funcao que recebe como parametro o endereÃ§o dos vetores RGB em $a0, $a1, $a2 e o tamanho dos mesmo em $a3
#Esta funcao encontra o valor minimo de cada vetor e retorna um vetor resultado com esses minimos 
	
	move $t0, $0
	li $t1, 255
	la $t2, result
	sb $0, 3($t2)
	
	loop1_minimiza:
		beq $t0, $a3, exit1_minimiza 
		lbu $t3, 0($a0)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor
		move $t1, $t3
		nao_menor:
		addi $a0, $a0, 1
		add $t0, $t0, 1
		j loop1_minimiza
	exit1_minimiza:	
		sb $t1, 2($t2)
		move $t0, $0
		li $t1, 255
		loop2_minimiza:
		beq $t0, $a3, exit2_minimiza 
		lbu $t3, 0($a1)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor2
		move $t1, $t3
		nao_menor2:
		addi $a1, $a1, 1
		add $t0, $t0, 1
		j loop2_minimiza
	exit2_minimiza: 	
		sb $t1, 1($t2)
		move $t0, $0
		li $t1, 255
	loop3_minimiza:
		beq $t0, $a3, exit3_minimiza 
		lbu $t3, 0($a2)
		slt $t4, $t3, $t1
		beq $t4, $0, nao_menor3
		move $t1, $t3
		nao_menor3:
		addi $a2, $a2, 1
		add $t0, $t0, 1
		j loop3_minimiza
	exit3_minimiza:
		sb $t1, 0($t2)
		jr $ra

				
###################################################################################################################################		
rafael: #Binarização

#colocando em tons de cinza
# rafael:
move $s7,$a0
li $a0,0x10040000 # endereço do inicio da imagem
mul $t2,$s4,$s4
mul $t2,$t2,4
add $t2,$t2,$a0
loop_cinza:

lbu $t0,0($a0) 
mtc1 $t0,$f4
mul.s $f4,$f4,$f0
mfc1 $t0,$f4 

lbu $t1,1($a0) 
mtc1 $t1,$f4
mul.s $f4,$f4,$f1
mfc1 $t1,$f4 


lbu $t3,2($a0) 
mtc1 $t3,$f4
mul.s $f4,$f4,$f2
mfc1 $t3, $f4 

add $t0,$t0,$t1
add $t3,$t3,$t0
sll $t0,$t3,16
sll $t1,$t3,8
or $t1,$t0,$t1
or $t1,$t3,$t1
sw $t1,0($a0)
addi $a0,$a0,4
beq $t2,$a0,fim_cinza
j loop_cinza
fim_cinza:
	
##########################################################################################

#contrução do histograma
li $a0,0x10040000
li $a1,0x10010400 # endereço do inicio  do histogrma
mul $t2,$s4,4
mul $t2,$t2,$s4
add $t2,$t2,$a0
#li $t1,1
hist:
lbu $t0,0($a0)
#sb $t0,0($a0)
mul $t0,$t0,4
add $t0,$t0,$a1
lw $t1,0($t0)
addi $t1,$t1,1
sw $t1,0($t0)
li $t1,0
addi $a0,$a0,4
beq $t2,$a0, fim_h
j hist
fim_h:

beq $s7,1,constante
beq $s7,2,otsu
beq $s7,3,interatividade
beq $s7,4,equilibrio
interatividade:
###########################################################################
# limimar calculado por iteratividade

li $a0,0x10010400 # endere
li $a2,0x10010400 # endere
li $a1, 127 #meio
mul $a1,$a1, 4 # endereço da word 
add $t0,$a1,$a0 # soma com o endereço base p ficar no meio de 0 -> 255

loop_novo_limiar:
li $t4,0 # zeramento
li $t5,0 # zeramento
li $t6,0 # zeramento
li $t7,0 # zeramento


# loop_novo_limear

li $t1,0x10010400 # endere
li $t2,0x100107fc # endere

loopg1:
lw $t3,($t1)
add $t4,$t4,$t3
beq $t1,$t0, g1 # se chegar no limiar pede p parar
addi $t1,$t1,4
addi $t6,$t6,1
j loopg1
g1:

loopg2:
lw $t3,($t2)
add $t5,$t5,$t3
beq $t2,$t0, g2 #se chegar no limiar pede p parar
addi $t2,$t2,-4
addi $t7,$t7,1
j loopg2
g2:

div $t4,$t4,$t6
div $t5,$t5,$t7
add $t8,$t4,$t5
div $t8,$t8,2

addi $t9,$t8, 60
addi $t8,$t8, -60
loop_limiar:

lw $s5,($a2) # endereço do novo limiar 
addi $a2,$a2, 4
slt $s6,$s5,$t9
slt $s7,$t8,$s5
add $s6,$s6,$s7
beq $s6,2,novo_limiar
j loop_limiar

novo_limiar:
subu $a3,$t0,$a2
slti $s0, $a3,32
beq $s0,1,fim_interativo
move $t0,$a2
li $a2,0x10010400
#li $v0, 12          
# syscall 
j loop_novo_limiar

fim_interativo:
sub $v1, $a2,$a0
div $v1,$v1,4
sll $t9,$v1,16
sll $t8,$v1,8
or  $t9,$t9,$t8
or  $t9,$t9,$v1
j binariza
#########################################################################
equilibrio:
# Limiarização por Equilíbrio do Histograma:
 
li $a0,0x10010400 
addi $a3,$a0,508
addi $a1,$a0,504
addi $a2,$a0,508

loop_th:
loope:
lw $s5,($a1)
#sw $s5,($a1)
add $t4,$t4,$s5

beq  $s5,0,fime
addi $a1,$a1,-4
j loope
fime:
loopd:
lw $s6,($a2)
#sw $s6,($a2)
add $t5,$t5,$s6

beq  $s6,0,fimd
addi $a2,$a2,4
j loopd
fimd:
beq $t4,$t5, sai_th
slt $t6,$t4,$t5 # se lado direito nais pesado t6 = 1
beq $t6,1, direito
addi $a1,$a1,4
sw $zero,($a1)
addi $a1,$a1,4
sw $zero,($a1)
addi $a3,$a3,4
addi $a1,$a3,-4
addi $a2,$a3,0
li $t4,0
li $t5,0
j loop_th
direito:
addi $a2,$a2,-4
sw $zero,($a2)
addi $a2,$a2,-4
sw $zero,($a2)
addi $a3,$a3,-4
addi $a1,$a3,-4
addi $a2,$a3,0
li $t4,0
li $t5,0
j loop_th
sai_th:
sub $t9,$a3,$a0
div $t9,$t9,4
addi $t9,$t9,-50
sll $v0,$t9,16
sll $v1,$t9,8
or  $v0,$v1,$v0  
or  $v0,$t9,$v0 
move $t9,$v0

j binariza
#####################################################################################
#metodo Otsu
otsu:
li $a0,0x10010400 # começo do vetor histogrma
li $t1,0x100107fc # fim do vetor  histogrma
li $s0,0
# parte da soma dos elementos do histograma 
loop_sum:
beq $t1,$a0,fim_sum
lw $t0,($a0)
add $s0,$s0,$t0  # $s0 fica com a soma dos elementos do vetor 
addi $a0,$a0,4
j loop_sum
fim_sum:
 
# fim
###########################################
# Normalização do histogrma
la $a0,0x10010400 # começo do vetor histogrma
li $t1,0x10010bfc # fim do vetor normalizado
li $a1,0x10010800 # inicio do vetor normalizado

mtc1 $s0,$f2
loop_norma:
lw $t0,($a0)
mtc1 $t0,$f0
div.s $f4,$f0,$f2
swc1 $f4,($a1) 
beq $t1,$a1,fim_norma
addi $a1,$a1,4
addi $a0,$a0,4
j loop_norma
fim_norma:

 # fim da normalização 
 ################################################################
# Soma acumulada : omega
 #li $v0, 12          
# syscall
li $a0,0x10010800 #começo do vetor Hnormal
li $a1,0x10010c00 #começo do vetor P (
li $t1,0x10010bfc # fim do vetor  Hnormal
add.s $f1,$f31,$f31
loop_omega:
lwc1 $f0,($a0)
add.s $f1,$f1,$f0
swc1 $f1,($a1)
beq $a0,$t1,fim_omega
addi $a1,$a1,4
addi $a0,$a0,4
j loop_omega
fim_omega:
add.s $f0,$f31,$f31
add.s $f2,$f31,$f31
add.s $f4,$f31,$f31
#Fim  omega

######################################################################
# contrução do mu
add.s $f0,$f31,$f31
add.s $f1,$f31,$f31
add.s $f2,$f31,$f31
add.s $f4,$f31,$f31

li $a0,0x10010800 # 
li $a1,0x10010bfc # fim do vetor  mu
li $t0,0x3f800000 # numero 1.0 3m complemento de 2
mtc1 $t0,$f10
add.s $f4,$f4,$f10

loop_mu1:
lwc1 $f2,($a0)
mul.s $f0,$f2,$f4
swc1 $f0,($a0)
beq $a0,$a1,fim_mu1
addi $a0,$a0,4
add.s $f4,$f4,$f10
j loop_mu1
fim_mu1:


li $a0,0x10010800 #começo do vetor p
li $a1,0x10010bfc #começo do vetor P
add.s $f1,$f31,$f31
loop_mu2:
lwc1 $f0,($a0)
add.s $f1,$f1,$f0
swc1 $f1,($a0)
beq $a0,$a1,fim_mu2
addi $a0,$a0,4
j loop_mu2
fim_mu2:
add.s $f0,$f31,$f31
add.s $f1,$f31,$f31
add.s $f2,$f31,$f31
add.s $f4,$f31,$f31
add.s $f10,$f31,$f31
#Fim mu

############################################################
#pegar o muT que é o ultimo elemento do mu
li $a1,0x10010bfc #final do vetor P
lwc1 $f5,($a1) # f5 gurda a contante muT
################################## 

li $a0,0x10011000 #começo do vetor muT.*omega
li $a1,0x100113fc #fim do vetor muT.*omega
li $a2,0x10010c00 #inicio do vetor omega
# a contante MuT está em $f5
loop_mo:
lwc1 $f0,($a2) # carregando os valores do vetor omega
mul.s $f2,$f5,$f0
swc1 $f2,($a0)
beq  $a0,$a1,fim_mo
addi $a0,$a0,4
addi $a2,$a2,4
j loop_mo
fim_mo:
# fim do vetor muT.*omega
#######################################
#contrução vetor muT.*omega - mu
#############################################

li $a0,0x10010800 # inicio do vetor  mu
li $a1,0x10010bfc # fim do vetor  mu
li $a2,0x10011000 #começo do vetor muT.*omega

loop_mo_m:
lwc1 $f0,($a2)
lwc1 $f2,($a0)
sub.s $f4,$f0,$f2
swc1 $f4,($a0)
beq  $a0,$a1,fim_mo_m
addi $a0,$a0,4
addi $a2,$a2,4
j loop_mo_m
fim_mo_m:
# #################################################
#Fim vetor muT.*omega - mu
#######################################################
#Construção do (vetor muT.*omega - mu).^2

li $a0,0x10010800 # inicio do vetor vetor muT.*omega - mu  
li $a1,0x10010bfc # fim do vetor  vetor muT.*omega - mu

loop_qua:
lwc1 $f0,($a0)
mul.s $f2,$f0,$f0
swc1 $f2,($a0) # (vetor muT.*omega - mu).^2 vai ficar no $a0
beq  $a0,$a1,fim_qua
addi $a0,$a0,4
j loop_qua
fim_qua:
#Fim vetor (muT.*omega - mu).^2
######################################################################
# contrução do vetor omega.*(1 - omega)

li $t0, 0x3f800000 # numero 1.0 em complemento de 2
mtc1 $t0,$f10
li $a0,0x10010c00 # inicio do vetor omega
li $a1,0x10010ffc # fim do vetor omega

loop_omega_1:
lwc1 $f0,($a0)
sub.s $f2,$f10,$f0
mul.s $f0,$f0,$f2
swc1 $f0,($a0)
beq $a0,$a1,fim_omega_1
add $a0,$a0,4
j loop_omega_1
fim_omega_1:
# fim do vetor omega.*(1-omega): esse vetor vai ficar no lugar do omega
#############################################################################
 #construção de sigma_b

 li $a0,0x10010800 #inicio do vetor vetor (muT.*omega - mu).^2
 li $a1,0x10010bfc # fim do vetor vetor (muT.*omega - mu).^2
 li $a2,0x10010c00 # inicio do vetor omega.*(1 - omega)
 
 loop_sigma_b:
 lwc1 $f0,($a0)
 lwc1 $f2, ($a2)
 div.s $f4,$f0,$f2
 swc1 $f4,($a0) # $ao tá com o endereço de sigma_b
 beq $a0,$a1,fim_sigma_b
 addi $a0,$a0,4
 addi $a2,$a2,4
 j loop_sigma_b
 fim_sigma_b: 
 #fim construção de sigma_b
 ##################################################################################
 # função para pegar o maior valor de sigma_b

 li $a0,0x10010820 #inicio do  endereço de sigma_b
 li $a1,0x10010bb4 # fim do sugam_b -1
 li $t1,0x00000000 # contante zero
 max:
lwc1 $f0,($a0)
mfc1 $t0,$f0
slt $t2,$t1,$t0
beq $t2,1, maior
beq $a0,$a1, fim_max
addi $a0,$a0,4
j max

maior:
move $t1,$t0
beq $a0,$a1, fim_max
addi $a0,$a0,4
j max
fim_max:
# fim max
##############################################################################

 li $a0,0x10010820 #inicio do  endereço de sigma_b
 li $a1,0x10010bb4 # fim do sugam_b
 li $t2,1
loop_T:
lwc1 $f0,($a0)
mfc1 $t0,$f0
beq  $t0,$t1,fim_T
addi $a0,$a0,4
addi $t2,$t2,1
j loop_T
fim_T:
sll $v0,$t2,16
sll $v1,$t2,8
or  $v0,$v1,$v0  
or  $v0,$t2,$v0 
move $t9,$v0
# o limimar T fica em $t2
j binariza
####################################################
###############################################################################
#Métodos dos minimos locais
constante:
li $t9,0x007f7f7f
binariza:
##########################################################################################
li $a0,0x10040000 # endereço do inicio da imagem
move $t0,$t9
li $t8,0x00000000 #black color
li $t7,0x00ffffff #white color 
mul $t2,$s4,$s4
li $t5,1
loop:
addi $t5,$t5,1
lw $t1,($a0) # carrega o primeiro pixel da imagem
slt $t3,$t1,$t0 # se a color carregada em em $t1 for menor que o liminae $t3 = 1
beq $t3,1,preto # vai para função que pinta de preto
sw  $t7,($a0) # pintando de branco
beq $t5,$t2,fim_bina # condição de parada no final do arquivo
addi $a0,$a0,4 # contador na área de dados
j loop
preto:
sw $t8,($a0) # pinta de preto
beq $t5,$t2,fim_bina # condição de parada no final do arquivo
addi $a0,$a0,4 # contador na área de dados
j loop

fim_bina: # final da função

jr $ra
		
		
####################################################################################################################################
#Efeito blur 
# Antonio
borra_imagem:

  
	addi,$sp,$sp,-4
	sw $ra,0($sp)
	addi $a0,$zero,2
	beq $a0,1,borra_imagem_2x2
	beq $a0,2,borra_imagem_4x4
	exit_final_borra_imagem:
		lw $ra,0($sp)
		addi $sp,$sp,4
		jr $ra
###################################################################################


###################################################################################
borra_imagem_2x2:

# Salva o conteúdo dos registradores para liberá-los para operações da função
sw $s1,tam_arquivo
sw $s2,offset
sw $s3,largura
sw $s4,altura

pepino_de_novo:
addi $t0,$zero,8
beq $t1,$t0,exit_borra
move $s0,$zero #$s0 = contador
move $s1,$zero #$s1 = pixel_x (pixel em operação)
lw $s2,largura #$s2 = largura
lw $s3,altura
mult $s2,$s3
mflo $s3 
subi $s3,$s3,1 #$s3 = (larguraxaltura)-1 = total de pixels

	pixel_main:
		add $t0,$s1,$s2
		subi $s2,$s2,1
		slt $t1,$s0,$s2
		add $s2,$s2,1
		slt $t2,$t0,$s3
		beq $t1,$t2,pixel_loop1
		beq $t1,$zero,pixel_loop2
		sll $s7,$s1,2
		li $s4,0x10040000
		add $s4,$s7,$s4
		addi $t1,$s4,4
		move $a1,$s4
		move $a2,$t1
		jal soma_pixel
		sw $v1,($s4)
		addi $s0,$s0,1
		addi $s1,$s1,1
		j pixel_main
		
		pixel_loop1:
			beq $t2,$zero,pixel_loop3 #vai embora filhão
			sll $s7,$s1,2
			li $s4,0x10040000
			add $s4,$s7,$s4
			move $s6,$s4 # guarda o endereço do pixel_x
			addi $t1,$s4,4
			move $a1,$s4
			move $a2,$t1
			jal soma_pixel
			move $s5,$v1
			sw $s5,0x10011000
			sll $s7,$s2,2
			add $s4,$s4,$s7
			addi $t1,$s4,4
			move $a1,$s4
			move $a2,$t1
			jal soma_pixel
			sw $v1,0x10011004
			li $a1,0x10011000
			li $a2,0x10011004
			jal soma_pixel
			sw $v1,($s6)
			addi $s1,$s1,1
			addi $s0,$s0,1
			j pixel_main
		pixel_loop2:
			sll $s7,$s1,2
			li $s4,0x10040000
			add $s4,$s7,$s4
			sll $s7,$s2,2
			add $t1,$s4,$s7
			move $a1,$s4
			move $a2,$t1
			jal soma_pixel
			sw $v1,($s4)
			move $s0,$zero
			addi $s1,$s1,1
			j pixel_main
 

pixel_loop3:
	lw $t1,passada_2x2
	addi $t1,$t1,1
	sw $t1,passada_2x2
	j pepino_de_novo
	exit_borra:
		lw $s1,tam_arquivo
		lw $s2,offset
		lw $s3,largura
		lw $s4,altura
		j exit_final_borra_imagem

##################################################################################

#soma os bytes R,G e B de dois pixels, faz a media de cada soma e retorna em $v1 um pixel composto pelas médias
#para usar carregue o endereço do pixel1 em $a1 e o endereço do pixel2 em $a2
soma_pixel:

lbu $t2,($a1)
lbu $t3,1($a1)
lbu $t4,2($a1)

lbu $t5,($a2)
lbu $t6,1($a2)
lbu $t7,2($a2)

add $t2,$t2,$t5
add $t3,$t3,$t6
add $t4,$t4,$t7

move $t5,$zero
addi $t5,$t5,2

div $t2,$t5
mflo $t2

div $t3,$t5
mflo $t3

div $t4,$t5
mflo $t4

sll $t3,$t3,8
sll $t4,$t4,16

or $t2,$t2,$t3
or $t2,$t2,$t4

move $v1,$t2

jr $ra
#############################################################################################################
borra_imagem_4x4:

# Salva o conteúdo dos registradores para liberá-los para operações da função
sw $s1,tam_arquivo
sw $s2,offset
sw $s3,largura
sw $s4,altura

pepino_de_novo_4x4:
addi $t1,$zero,2
beq $t0,$t1,exit_de_verdade
move $s0,$zero #$s0 = contador
move $s1,$zero #$s1 = pixel_x (pixel em operação)
lw $s2,largura #$s2 = largura
lw $s3,altura
mult $s2,$s3
mflo $s3 
subi $s3,$s3,1 #$s3 = (larguraxaltura)-1 = total de pixels

#teste1
add $t0,$s1,$s2
add $t0,$t0,$s2 #$t0 = pixel_x + largura + largura
addi $t1,$s1,2 #$t1 = pixel_x + 2


borra_imagem_4x4_main:

#teste0
beq $s1,$s3,exit_borra_imagem_4x4

#teste 1 x+largura+largura< total?
slt $t3,$t0,$s3
#teste 2
slt $t4,$t1,$s2

beq $t3,$t4,caso_1
beq $t3,$zero,caso_3
j caso_4

caso_1: #teste 1 = 0 e teste2 = 0
	bne $t3,$zero,caso_2
	jal borra_matriz_2x2
	sw $v1,($s4)
	addi $s0,$s0,1
	addi $s1,$s1,1
	j borra_imagem_4x4_main
		
caso_2: #teste1 = 1 e teste2 = 1
	jal borra_matriz_2x2
	sw $v1,soma1
	
	add $s1,$s1,2
	jal borra_matriz_2x2
	sw $v1,soma2
	
	add $s1,$s1,$s2
	add $s1,$s1,$s2
	jal borra_matriz_2x2
	sw $v1,soma4
	
	subi $s1,$s1,2
	jal borra_matriz_2x2
	sw $v1,soma3
	
	la $a1,soma1
	la $a2,soma2
	jal soma_pixel
	sw $v1,soma1
	
	la $a1,soma3
	la $a2,soma4
	jal soma_pixel
	sw $v1,soma2
	
	la $a1,soma1
	la $a2,soma2
	jal soma_pixel
	
	sub $s4,$s4,$s2
	sub $s4,$s4,$s2
	sw $v1,($s4)
	
	addi $s0,$s0,1
	addi $s1,$s1,1
	j borra_imagem_4x4_main
	

caso_3: #teste1 = 0 e teste2 = 1
	jal borra_matriz_2x2
	sw $v1,soma1
	
	addi $s1,$s1,2
	jal borra_matriz_2x2
	sw $v1,soma2
	
	la $a1,soma1
	la $a2,soma2
	jal soma_pixel
	
	subi $s1,$s1,2
	sw $v1,($s4)
	
	addi $s0,$s0,1
	addi $s1,$s1,1
	j borra_imagem_4x4_main

caso_4: #teste1 = 1 e teste2 = 0
	jal borra_matriz_2x2
	sw $v1,soma1
	
	add $s1,$s1,$s2
	add $s1,$s1,$s2
	jal borra_matriz_2x2
	sw $v1,soma2
	
	la $a1,soma1
	la $a2,soma2
	jal soma_pixel
	
	sub $s1,$s1,$s2
	sub $s1,$s1,$s2
	sw $v1,($s4)
	
	subi $t0,$s2,1
	bne $t0,$s0,n_zera_contador
	move $s0,$zero
	addi $s1,$s1,1
	j borra_imagem_4x4_main
	n_zera_contador:
	addi $s0,$s0,1
	addi $s1,$s1,1
	j borra_imagem_4x4_main

exit_borra_imagem_4x4:
lw $t0,passada_4x4
addi $t0,$t0,1
sw $t0,passada_4x4
j pepino_de_novo_4x4

exit_de_verdade:
lw $s1,tam_arquivo
lw $s2,offset
lw $s3,largura
lw $s4,altura
j exit_final_borra_imagem


#############################################################################################################
borra_matriz_2x2:

	pixel_main_2x2:
		add $t0,$s1,$s2
		slt $t1,$s0,$s2
		slt $t2,$t0,$s3
		beq $t1,$t2,pixel_loop1_2x2
		beq $t1,$zero,pixel_loop2_2x2
		sll $s7,$s1,2
		li $s4,0x10040000
		add $s4,$s7,$s4
		addi $t1,$s4,4
		move $a1,$s4
		move $a2,$t1
		addi $sp,$sp,-4
		sw $ra,0($sp)
		jal soma_pixel
		lw $ra,0($sp)
		addi $sp,$sp,4
		j exit_borra_matriz_2x2
		
		pixel_loop1_2x2:
			beq $t2,$zero,exit_borra_matriz_2x2 #vai embora filhão
			sll $s7,$s1,2
			li $s4,0x10040000
			add $s4,$s7,$s4
			move $s6,$s4 # guarda o endereço do pixel_x
			addi $t1,$s4,4
			move $a1,$s4
			move $a2,$t1
			addi $sp,$sp,-4
			sw $ra,0($sp)
			jal soma_pixel
			lw $ra,0($sp)
			addi $sp,$sp,4
			move $s5,$v1
			sw $s5,0x10011000
			sll $s7,$s2,2
			add $s4,$s4,$s7
			addi $t1,$s4,4
			move $a1,$s4
			move $a2,$t1
			addi $sp,$sp,-4
			sw $ra,0($sp)
			jal soma_pixel
			lw $ra,0($sp)
			addi $sp,$sp,4
			sw $v1,0x10011004
			li $a1,0x10011000
			li $a2,0x10011004
			addi $sp,$sp,-4
			sw $ra,0($sp)
			jal soma_pixel
			lw $ra,0($sp)
			addi $sp,$sp,4
			move $s4,$s6
			j exit_borra_matriz_2x2
		pixel_loop2_2x2:
			sll $s7,$s1,2
			li $s4,0x10040000
			add $s4,$s7,$s4
			sll $s7,$s2,2
			add $t1,$s4,$s7
			move $a1,$s4
			move $a2,$t1
			addi $sp,$sp,-4
			sw $ra,0($sp)
			jal soma_pixel
			lw $ra,0($sp)
			addi $sp,$sp,4
 
exit_borra_matriz_2x2:

jr $ra
##################################################################################################################################
		
	