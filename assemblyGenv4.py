# Rafael de Camargo Sampaio
# Carolina Braun Prado
# GRUPO 1
import sys
import re

# VARIAVEIS GLOBAIS
MEM = None  # armazena posicao no historico
RES = 0     # contador de expressoes processadas
INSTR_ID = 0
debug_output = []  # salva linha e resultado em float

# quebra um numero float em parte inteira, fracionaria e sinal
def parse_num(token):
    if '.' in token:
        int_part, frac = token.split('.')
        frac = (frac + '0000')[:4]
    else:
        int_part, frac = token, '0000'
    sinal = '1' if token.strip().startswith('-') else '0'
    return int(int_part.replace("-","")), int(frac), sinal

# monta bloco de assembly para carregar um numero
def load_number_block(int_val, frac_val, sign, target):
    if int_val > 65535 or frac_val > 65535:
        raise ValueError("Valor fora do limite permitido (65535)")

    r = ['r19', 'r18', 'r17', 'r16'] if target == 'primary' else ['r23', 'r22', 'r21', 'r20']
    
    block = f"""
    ; Load {target} number
    ldi {r[0]}, high({int_val})
    ldi {r[1]}, low({int_val})
    ldi {r[2]}, high({frac_val})
    ldi {r[3]}, low({frac_val})
    """
    sign_bit = '0b00000001' if sign == '1' and target == 'primary' else \
               '0b00000010' if sign == '1' else \
               '0b00000000'
    block += f"ldi r24, {sign_bit}\n"
    return block

# traduz operador para chamada em assembly
def to_op_code(op):
    return {
        '+': "    call add_int_numbers",
        '-': "    call sign_inverter\n    call add_int_numbers",
        '*': "    call mul_int_numbers",
        '/': "    call div_int_int_numbers",
        '|': "    call div_real_int_numbers",
        '%': "    call rest_numbers",
        '^': "    call power_int_numbers"
    }.get(op, f"; Unsupported op: {op}")

def is_primary(tokens, index):
    try:
        if tokens[index+2] in "+-*/|%^": return True
        else: return False
    except:
        return False

def is_calculable_mem(tokens, index):
    try: 
        if tokens[index-1] in "+-*/|%^": return True
        elif tokens[index-2] in "+-*/|%^": return True
        else: return False
    except:
        return False
    
def push_assembly():
        asm="""
    push r24
    push r16
    push r17
    push r18
    push r19
        """
        return asm

def pop_assembly(number):
    if number == 'primary':
        asm = """
    pop r19
    pop r18
    pop r17
    pop r16
    pop r25
    call mem_to_primary
"""
        return asm
    elif number == 'secondary':
        asm = """
    pop r23
    pop r22
    pop r21
    pop r20
    pop r25
    call mem_to_secondary
"""
        return asm
    else:
        return None

# avalia expressao RPN e gera assembly
def evaluate_rpn(tokens, linestack, lineExpr):
    global INSTR_ID, MEM, RES
    asm = ""
    for i in range(len(tokens)):
        token = tokens[i]

        if isinstance(token, list) and token[1]=="RES":  # caso (N RES)
            line = int(token[0]) - 1
            if line <= RES:
                linestack.append(lineExpr[line][1])

                # ASSEMBLY
                asm += lineExpr[line][0]
            else:
                return None 
            
        elif isinstance(token, list): # caso aninhado
            asm_sub, linestack, r_sub = evaluate_rpn(token,linestack,lineExpr)
            linestack.append(str(r_sub))
            
            # ASSEMBLY
            asm += asm_sub

        elif re.match(r'^-?\d+(\.\d+)?$', token):  # numero inteiro
            linestack.append(token)
            
            # ASSEMBLY
            primary_int, primary_frac, primary_sign = parse_num(token)
            
            asm += load_number_block(primary_int, primary_frac, primary_sign, 'primary')
            asm += push_assembly()

        elif token == "MEM":
            if is_calculable_mem(tokens, i): #recupera valor
                if MEM != None:
                    linestack.append(lineExpr[MEM][1])

                    # ASSEMBLY
                    asm += lineExpr[MEM][0]
                else:                           # caso (V MEM)
                    linestack.append(0)

                    # ASSEMBLY
                    primary_int, primary_frac, primary_sign = parse_num('0')
                
                    asm += load_number_block(primary_int, primary_frac, primary_sign, 'primary')
                    asm += push_assembly()
            
            else:
                MEM = RES
                return asm, linestack, float(linestack.pop(-1))

        elif token in "+-*/|%^": # caso operação
            secondary = float(linestack.pop(-1))
            primary = float(linestack.pop(-1))

            if (token == '|' or token == '/') and secondary == 0.0:
                return None
            
            if (token == '^' and secondary < 0) or token == '^' and not (isinstance(secondary, float) and secondary.is_integer()):
                return None

            try:
                if token != '|':
                    if token == '^': r = f"{primary**secondary:.4f}"
                    elif token == '/': r = f"{primary/secondary:.0f}"
                    else: r = eval(f"{primary}{token}{secondary}")
                else:
                    r = f"{primary / secondary:.4f}"
            except:
                r = 0

            # ASSEMBLY
            asm += """
    clr r24\n"""
            asm += pop_assembly('secondary') 
            asm += pop_assembly('primary') 
            asm += to_op_code(token) + "\n"
            asm += push_assembly()
            
            INSTR_ID += 1

        else:
            raise ValueError(f"Token invalido: {token}")

    return asm, linestack, r

# separa tokens RPN aninhados
def tokenize_rpn_nested(expr: str):
    expr = expr.strip()
    stack = [[]]
    token = ''
    for c in expr:
        if c == '(':
            stack.append([])
        elif c == ')':
            if token:
                stack[-1].append(token)
                token = ''
            val = stack.pop()
            stack[-1].append(val)
        elif c == ' ':
            if token:
                stack[-1].append(token)
                token = ''
        else:
            token += c
    if token:
        stack[-1].append(token)
    return stack[0][0]

# processa o arquivo txt e monta o .asm final
def processar_arquivo(nome_arquivo, arquivo_base):
    global RES
    lineExpr = []

    with open(arquivo_base) as base_file:
        codigo_base = base_file.read()

    with open(nome_arquivo) as f:
        linhas = f.readlines()

    # SETUP
    setup = """
setup:
    ldi r16, high(RAMEND)
    sts SPH, r16
    ldi r16, low(RAMEND)
    sts SPL, r16
    call config_usart
    
    clr r17
    clr r18
    clr r19
    clr r20
    clr r21
    clr r22
    clr r23
    clr r24

    ldi r30, 13
    call send_char_call_no_Correction
    
    rjmp main

main:
"""

    # BODY
    body = ""

    for idx, linha in enumerate(linhas):
        linestack = []
        try:
            tokens = tokenize_rpn_nested(linha.strip())
            asm, linestack, result = evaluate_rpn(tokens,linestack,lineExpr)
            lineExpr.append([asm,result])
            asm += pop_assembly('primary')
        except Exception as e:
            asm = f"; Erro ao processar linha: {linha.strip()} - {str(e)}\n"
            result = "Erro"
            lineExpr.append([None,result])

        debug_output.append((linha.strip(), result))
        body += asm
        if result != "Erro":
            body += """
    call send_sign_primary
    call send_full_byte_decimal_primary
    ldi r30, '|'
    call send_char_call_no_Correction
    clr r24
        """
            body += "\n; --------------------------\n"
        RES += 1
    
    # FINAL
    final = """
    ldi r30, 13
    call send_char_call_no_Correction
    call delay
    end_of_code_really:
    rjmp end_of_code_really
    """
    return codigo_base + "\n" + setup + body + final

# main executa usando sys.argv ao inves de input
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python programa.py arquivo.txt")
        sys.exit(1)

    nome_arquivo = sys.argv[1]
    base_arquivo = 'base.asm'  # tem que estar no mesmo diretorio
    assembly_code = processar_arquivo(nome_arquivo, base_arquivo)

    with open("assembly_out/saida.asm", "w") as out:
        out.write(assembly_code)

    print("resultados em py:")
    for expr, val in debug_output:
        print(f"{expr} = {val if isinstance(val, str) else f'{val:.4f}'}")

