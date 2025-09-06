.data
buffer:   .space 100
s1:       .space 8
s2:       .space 8
name_table:      .space 1350000      
name_count:      .word 0
net_balance:     .space 1200000
debt_entries:    .space 2400000  
debt_count:      .word 0

.text
.globl main
main:
  
    li a7, 5
    ecall
    mv s0, a0      # s0 ← q

loop_start:
    beqz s0, end  

# خواندن خط دستور
    li a7, 8
    la a0, buffer
    li a1, 100
    ecall
	
	
    la t0, buffer
    call parse_integer   # شماره دستور → a0
    mv t1, a0

    li t2, 1
    beq t1, t2, case1
    li t2, 2
    beq t1, t2, case2
    li t2, 3
    beq t1, t2, case3
    li t2, 4
    beq t1, t2, case4
    li t2, 5
    beq t1, t2, case5
    li t2, 6
    beq t1, t2, case6

    j after_case

# ------------------------
case1:  # 1 s1 s2 x
    la a0, s1
   call parse_string    
	
	mv s1 , a0
	
    la a0, s2
    call parse_string    
	
	mv s2 , a0
    
    call parse_float      
    mv t2, t1            #int part
    mv t3  , t4          #frc part
	
	
   
    call get_index
	
    mv t0, a0             # index_s1 → t0
    
	
    mv s1 , s2
    call get_index
	
    mv t4, a0             # index_s2 → t4
    
    la      s3 , debt_entries
	la      s4,  net_balance
    la      s5 , debt_count
    lw      t1 , 0(s5)  
	
	li      t5 , 0               # i = 0
	
	
find_debt_loop:
	bge     t5 ,t1, debt_not_found
	
	li t6,16
	mul   t6, t5 , t6          # offset = i*16
    add     t6, t6, s3         # آدرس رکورد = base + offset
	
	lw      s6, 0(t6)          # from
    lw      s7, 4(t6)          # to
	bne     s6, t0, next_debt
    bne     s7, t4, next_debt
	
	 # رکورد پیدا شد
    lw      s8 , 8(t6)          # old_int_part
    lw      s6 , 12(t6)         # old_frac_part

	
	
    li      s9 , 100
    blt     s6 , s9 , no_carry
	
	sub     s6, s6, s9         # frac -= 100
    addi    s8, s8, 1          # carry → int++
	
no_carry:
    add     s8, s8, t2         # int += x_int
	
	
	sw      s8 , 8(t6)
    sw      s6 , 12(t6)
	
    j       update_net_balance
	
	
next_debt:
    addi    t5, t5, 1
    j       find_debt_loop
	
debt_not_found:

    li t6,16
    mul    t6, t1, t6
    add     t6, t6, s3
    
    sw      t0, 0(t6)      
    sw      t4, 4(t6)
    sw      t2, 8(t6)
    sw      t3, 12(t6)
	
    addi    t1, t1, 1          # افزایش تعداد رکوردها

update_net_balance:
     # کاهش net_balance[s1]
    slli    s6, t0 , 3
    add     s7, s4, s6

    lw      s8, 0(s7)     
    lw      t6, 4(s7)

    sub     t6, t6, t3
    bgez    t6, no_borrow

    addi    t6, t6, 100
    addi    s8, s8, -1
	
no_borrow:
    sub     s8, s8, t2
    sw      s8, 0(s7)
    sw      t6, 4(s7)

    # افزایش به net_balance[s2]
    slli    s6, t4 , 3
    add     s7, s4, s6

    lw      s8, 0(s7)
    lw      t6, 4(s7)

    add     t6, t6, t3
    li      s9, 100
    blt     t6, s9, store_balance

    sub     t6, t6, s9
    addi    s8, s8, 1

store_balance:
    add     s8, s8, t2
    sw      s8, 0(s7)
    sw      t6 , 4(s7)
	sw      t1 , 0(s5)
	j after_case
# ------------------------
case2:
	li      t0, -1             # best_index = -1
    li      t1, 0              # best_int = 0
    li      t2, 0              # best_frac = 0
    li      t3, 0              # i = 0
	la      t4 , name_count
	lw      t4 , 0(t4)
	la      s1, net_balance
	la      s2, name_table
	
    addi sp, sp, -16     
    sw ra, 0(sp)          
    sw s1, 4(sp)          
    sw s6, 8(sp)           
    sw s7, 12(sp)          

c2_loop:
   
    beq    t3, t4 , c2_check_result

    slli    t5, t3, 3           # offset = i * 8
    add     t6, s1, t5

    lw      s3, 0(t6)           # cur_int
    lw      s4, 4(t6)           # cur_frac
	

    bltz    s3, c2_next         # اگر منفی بود، رد شو
    beqz    s3, check_frac_2
    j       check_better
	
check_frac_2:
    blez    s4, c2_next       
	
check_better:
    # مقایسه بزرگتر بودن (cur > best)
    bgt     s3, t1, update_best
    blt     s3, t1, c2_next
    bgt     s4, t2, update_best
    blt     s4, t2, c2_next

    # اگر مساوی بودن → مقایسه اسم
    # a0 = names[i]
	li t5 , 9
	mul     t5 , t3 , t5
    add     t6, s2, t5
   
	
	lb s9 , 0(a0)
	mv a0 , s9 
	
   
    # a1 = names[best_index]
    mul   t5 , t0 , t5
    add     t6, s2, t5
    addi     a1, t6 , 0

    lb s9 , 0(a1)
	mv a0 , s9 

    call    strcmp        


    bltz    a0, update_best   
    j       c2_next
	
update_best:
    move    t0, t3              # best_index = i
    move    t1, s3              # best_int
    move    t2, s4              # best_frac
	
c2_next:
    addi    t3, t3, 1
    j       c2_loop
	
c2_check_result:

    bltz    t0, c2_print_minus1
	
    li s9 , 9
    # چاپ name[best_index]
    mul   t5 , t0 , s9
    add   t6, s2, t5
	
print2:
     lb a0 , 0(t6)
	 beqz a0 , end2
	 
     li a7,11
	 ecall
	
	 addi t6 , t6 , 1
	 j print2
	
c2_print_minus1:
    li      a0, -1
    li      a7, 1
    ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
    j after_case
end2:
    li a7 ,11
    li a0 ,10
	ecall
	
    lw ra, 0(sp)
    lw s1, 4(sp)
    lw s6, 8(sp)
    lw s7, 12(sp)
    addi sp, sp, 16
    j after_case

# --------------------------
case3:
    li      t0, -1             # worst_index = -1
    li      t1, 0              # worst_int
    li      t2, 0              # worst_frac
    li      t3, 0              # i = 0
	la      t4 , name_count
	lw      t4 , 0(t4)
	la      s1, net_balance
	la      s2, name_table
c3_loop:
    bge     t3, t4, c3_check_result  
	
	slli    t5, t3, 3           # offset = i * 8
    add     t6, s1, t5
	
	lw      s3, 0(t6)           # cur_int
    lw      s4, 4(t6)           # cur_frac
	
    # اگر مثبت بود، رد شو
    bltz    s3, check_worse
    beqz    s3, check_frac_3
    j       c3_next
	
check_frac_3:
    bltz    s4, check_worse
    j       c3_next

check_worse:
    # مقایسه cur < worst
    blt     s3, t1, update_worst
    bgt     s3, t1, c3_next
    blt     s4, t2, update_worst
    bgt     s4, t2, c3_next
	
    # a0 = names[i]
	li t5 , 9
	mul     t5 , t3 , t5
    add     t6, s2, t5
    addi    a0, t6 , 0
	
    lb s9 , 0(a0)
	mv a0 , s9
	
	# a1 = names[worst_index]
    mul     t5 , t0 , t5
    add     t6, s2, t5
    addi    a1, t6 , 0
	
	lb s9 , 0(a1)
	mv a0 , s9
	
	call    strcmp        
    bltz    a0, update_worst    
    j       c3_next
	
update_worst:
    mv    t0, t3
    mv    t1, s3
    mv    t2, s4

c3_next:
    addi    t3, t3, 1
    j       c3_loop
	
c3_check_result:
    bltz    t0, c3_print_minus1
	
	li s9 , 9
    # چاپ name[best_index]
    mul   t5 , t0 , s9
    add   t6, s2, t5

print3:
    lb a0 , 0(t6)
	beqz a0 , end3
	 
    li a7,11
	ecall
	
	addi t6 , t6 , 1
	j print3
c3_print_minus1:
    li      a0, -1
    li      a7, 1
    ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
    j after_case
end3:
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
# --------------------------
case4:
    la a0, s1
    call parse_string
	mv s1, a0

	call get_index
    
	li      t0, 0           # i ← index entry
    li      t1, 0           # count ← 0
    la      s2 , debt_entries
	la      t2 , debt_count
	lw      t2 , 0(t2)
	
c4_loop:
    bge     t0, t2, c4_done
	
	# آدرس entry = s2 + 16 * t0
    li      t3, 16
    mul     t4, t0, t3
    add     t5, s2, t4
	
	lw      t6, 0(t5)     # from
    lw      s3, 4(t5)     # to
	lw      s4 , 8(t5)    #int
	lw      s5 , 12(t5)   #frc

	bne     s3, a0, c4_next   
    li s10 ,0
	li s11 , 0
	li s6,0
	j check4
check4:
	bge     s6, t2, continue4
	li      s7, 16
    mul     s7, s6, s7
    add     s7, s2, s7
	
	lw      s8, 0(s7)     # from
    lw      s9, 4(s7)     # to
	
	addi    s6 , s6 , 1
	bne     s3, s8 , check4
	bne     t6 , s9 , check4
	lw      s10 , 8(s7)
	lw      s11 , 12(s7)
	j continue4
	
continue4:
    bgt     s10 , s4 , c4_next
	beq     s10 , s4 , c4_frc
	addi    t1, t1, 1
	j c4_next
c4_frc:
    bge     s11, s5 , c4_next
	addi    t1,t1,1
	j c4_next
c4_next:
    addi    t0, t0, 1
    j       c4_loop

c4_done:
    mv      a0, t1
    li      a7 , 1
    ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
# --------------------------

case5:
    la a0, s1
    call parse_string
	mv s1, a0
	call get_index
	
	li      t0, 0           # i ← index entry
    li      t1, 0           # count ← 0
    la      s2 , debt_entries
	la      t2 , debt_count
	lw      t2 , 0(t2)

c5_loop:
    bge     t0, t2, c5_done
	
	# آدرس entry = s2 + 16 * t0
    li      t3, 16
    mul     t4, t0, t3
    add     t5, s2, t4
	
	lw      t6, 0(t5)     # from
    lw      s3, 4(t5)     # to
	lw      s4, 8(t5)       # int_part
    lw      s5, 12(t5)       # frac_part
	
	bne     t6, a0, c5_next   
    li s10 ,0
	li s11 , 0
	li s6,0
	j check5
check5:
	bge     s6, t2, continue5
	li      s7, 16
    mul     s7, s6, s7
    add     s7, s2, s7
	
	lw      s8, 0(s7)     # from
    lw      s9, 4(s7)     # to
	
	addi    s6 , s6 , 1
	bne     s3, s8 , check5
	bne     t6 , s9 , check5

	lw      s10 , 8(s7)  #int
    lw      s11 , 12(s7) #frac
	j continue5
	
continue5:
    bgt     s10 , s4 , c5_next
	beq     s10 , s4 , c5_frc
	addi    t1, t1, 1
	j c5_next
c5_frc:
    bge     s11, s5 , c5_next
	addi    t1,t1,1
	j c5_next
	
c5_next:
    addi    t0, t0, 1
    j       c5_loop

c5_done:
    mv      a0, t1
    li      a7 , 1
    ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
# ------------------------
case6:
     la a0, s1
   call parse_string    
	
	mv s1 , a0
	
    la a0, s2
    call parse_string    
	
	mv s2 , a0

    call get_index
    mv t0, a0             # index_s1 → t0
               
    mv s1 , s2
    call get_index
    mv t1, a0             # index_s2 → t1
    
	li      t2, 0          # index
    li      t3, 0          #sum int part
	li      t4 , 0         #sum frc part
	la      s3,  debt_entries
	la      s4 , debt_count
	lw      t5 , 0(s4)
c6_loop:
    beq     t2 , t5 , c6_done
	
    li t6,16
    mul    t6 , t2 , t6
	add    t6 , s3 , t6
	
    lw      s5, 0(t6)      # from
    lw      s6, 4(t6)      # to
    lw      s7, 8(t6)      # int
    lw      s8, 12(t6)     # frc

	
	bne     s6, t0 , c6_check_rev
    bne     s5, t1,  c6_next
    
	# match: s1 → s2
	add  t3 , t3 , s7
	add  t4 , t4 , s8
 
	j c6_next
c6_check_rev:
    bne     s5 , t0 , c6_next
    bne     s6 , t1 , c6_next
	
	
	sub  t3 , t3 , s7
	sub  t4 , t4 , s8
	
	
	j c6_next
c6_next:
    addi    t2, t2, 1
    j       c6_loop
c6_done:
    bltz t3 , c6_neg
	bltz t4 , c6_pos_neg
	
    mv  a0 , t3
	li a7,1
	ecall
	
	li a0 , '.'
	li a7,11
	ecall
	
	li s9,10
	blt t4 , s9 , two_digit
    mv   a0 , t4
	li a7,1
	ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
two_digit:
    li a0,0
	li a7,1
	ecall
	
    mv  a0 , t4
	li a7,1
	ecall
    
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
c6_neg:
    bgtz t4 , c6_neg_pos
   
    mv  a0 , t3
	li a7,1
	ecall
	
	li a0 , '.'
	li a7,11
	ecall
	
	neg t4 , t4
	li s9,10
	blt t4 , s9 , two_digit
	
    mv   a0 , t4
	li a7,1
	ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
c6_pos_neg:
    addi t3 , t3 , -1
	addi t4 , t4 , 100
    mv  a0 , t3
	li a7,1
	ecall
	
	li a0 , '.'
	li a7,11
	ecall
	
	li s9,10
	blt t4 , s9 , two_digit
	
    mv   a0 , t4
	li a7,1
	ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
    j after_case
c6_neg_pos:
    addi t3 , t3 ,1
	addi t4 , t4 , -100
	 mv  a0 , t3
	li a7,1
	ecall
	
	li a0 , '.'
	li a7,11
	ecall
	
	neg t4 , t4
	li s9,10
	blt t4 , s9 , two_digit
	
    mv   a0 , t4
	li a7,1
	ecall
	
    li a7 ,11
	li a0 ,10
	ecall
	
	j after_case
# ------------------------
after_case:
    addi s0, s0, -1
    j loop_start

# --------------------------
parse_integer:
    li t1, 0
parse_int_loop:
    lbu t2, 0(t0)
    beqz t2, parse_done
    li t3, ' '
    beq t2, t3, parse_skip_space
    li t3, '0'
    blt t2, t3, parse_done
    li t4, '9'
    bgt t2, t4, parse_done
    sub t2, t2, t3
    li t3, 10
    mul t1, t1, t3
    add t1, t1, t2
    addi t0, t0, 1
    j parse_int_loop

parse_skip_space:
    addi t0, t0, 1
    j parse_int_loop

parse_done:
    mv a0, t1
    jr ra

# --------------------------
parse_string:
    mv t3, a0       

parse_str_loop:
    lbu t2, 0(t0)
    li t4, ' '
    beq t2, t4, parse_str_end
	li   t4, 9     # tab
    beq  t2, t4, parse_str_end
    li   t4, 10    # LF '\n'
    beq  t2, t4, parse_str_end
    sb t2, 0(t3)
    addi t3, t3, 1
    addi t0, t0, 1
    j parse_str_loop

parse_str_end:
    li t5 ,0
    sb t5, 0(t3)

skip_spaces:
    lbu t2, 0(t0)
    li t3, ' '
    beq t2, t3, skip_spaces_inc
    jr ra
skip_spaces_inc:
    addi t0, t0, 1
    j skip_spaces
	
# --------------------------
parse_float:
   li t1, 0  
parse_flt_loop:
   lb t2, 0(t0) 
   li t3 , 46
   beq t2, t3, parse_frac_start  # if '.', go to fraction
   li t3 , 10
   beq t2, t3, parse_flt_done 
   li t3, 48
   sub t2, t2, t3       # convert ASCII to digit
   li t3, 10
   mul t1, t1, t3       
   add t1, t1, t2       

   addi t0, t0, 1
   j parse_flt_loop
   
parse_frac_start:
    addi t0, t0, 1       # skip the '.'

    li t4, 0             

parse_frac:
    lb t2, 0(t0)
	li t3 , 10
    beq t2, t3, parse_flt_done  

    li t3, 48
    sub t2, t2, t3       # ASCII to digit
    li t3, 10
    mul t4, t4, t3
    add t4, t4, t2      

    addi t0, t0, 1
    j parse_frac
parse_flt_done:
    mv a0, t1
    jr ra
# --------------------------
get_index:
    addi sp, sp, -16      
    sw ra, 0(sp)          
    sw s1, 4(sp)           
    sw s6, 8(sp)          
    sw s7, 12(sp)         

    la s3, name_table      # آدرس جدول اسامی
    la s4, name_count      # آدرس شمارنده اسامی

    li t1, 0               # i = 0
loop_find:
    lw t4, 0(s4)           # t4 = name_count
    beq t1, t4, not_found 
	
    li t5, 9               # طول هر اسم 8 بایت
    mul t6, t1, t5         # offset = i * 9
    add s5, s3, t6         # s5 = name_table + offset

    mv s6, s5
    mv a0, s1         
	mv a1, s6         # رشته‌ای از جدول
	
	call strcmp       # مقایسه s1 با s6
	
	beqz a0, found         # اگر برابر بودن، پیدا شده

    addi t1, t1, 1         
    j loop_find

not_found:
    li t5, 9
    lw t4, 0(s4)           # t4 = name_count
    mul t6, t4, t5
    add s7, s3, t6         # s7 = name_table + name_count * 8

    mv a1, s7              # مقصد
    mv a2, s1              # مبدا
    call strcpy           
    

    mv a0, t4              
    addi t4, t4, 1         # name_count++
    sw t4, 0(s4)

    j end_get_index

found:
    mv a0, t1              

end_get_index:
    lw ra, 0(sp)
    lw s1, 4(sp)
    lw s6, 8(sp)
    lw s7, 12(sp)
    addi sp, sp, 16
    jr ra
# --------------------------
strcmp:
    
strcmp_loop:
  
    lb      s8, 0(a0)      
    lb      s9, 0(a1)     
    
    beqz    s9 , strcmp_equal
    bne     s8, s9 , not_equal    
  
	
    addi    a0 , a0 , 1      
    addi    a1  , a1 , 1
    j       strcmp_loop
not_equal:
    sub     a0, s8 ,  s9
    jr ra
strcmp_equal:
    li      a0, 0
    jr ra

# --------------------------
strcpy: 

strcpy_loop:
    lb      s8 , 0(a2)        # خواندن یک کاراکتر از مبدا
    sb      s8 , 0(a1)        # نوشتن آن در مقصد
       
   beq     s8 , zero , strcpy_done  

   addi    a1, a1, 1        
   addi    a2, a2, 1
   
   j       strcpy_loop

  strcpy_done:
  jr ra
# ------------------------
end:
    li a7, 10
    ecall