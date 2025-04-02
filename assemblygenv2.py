import sys
import re

# GLOBALS
MEM = None #memoria temporaria
RES = [] #resultados
INSTR_ID = 0  #contador de instrucoes
debug_output = []


def parse_num(token): #quebra int e dec
    if '.' in token:
        int_part, frac = token.split('.')
        frac = (frac + '0000')[:4]
    else:
        int_part, frac = token, '0000'
    sinal = '1' if token.strip().startswith('-') else '0'
    return int(int_part), int(frac), sinal


def load_number_block(int_val, frac_val, sign, target): # logica de carregamento
    int_hi, int_lo = divmod(int_val, 256)
    frac_hi, frac_lo = divmod(frac_val, 256)
    r = ['r19', 'r18', 'r17', 'r16'] if target == 'primary' else ['r23', 'r22', 'r21', 'r20']
    block = f"""
    ; Load {target} number
    ldi {r[0]}, {int_hi}
    ldi {r[1]}, {int_lo}
    ldi {r[2]}, {frac_hi}
    ldi {r[3]}, {frac_lo}
    """
    sign_bit = '0b00000001' if sign == '1' and target == 'primary' else \
               '0b00000010' if sign == '1' else \
               '0b00000000'
    block += f"ori r24, {sign_bit}\n"
    return block


def to_op_code(op): #funcoes
    return {
        '+': "call add_int_numbers",
        '-': "call sign_inverter\ncall add_int_numbers",
        '*': "call mul_int_numbers",
        '/': "call div_int_int_numbers",
        '|': "call div_real_int_numbers",
        '%': "call rest_numbers",
        '^': "call power_int_numbers"
    }.get(op, f"; Unsupported op: {op}")


def evaluate_rpn(tokens): 
    stack = []
    asm = ""
    global INSTR_ID

    for token in tokens:
        if isinstance(token, list):  # expressão aninhada
            asm_sub, result_py = evaluate_rpn(token)
            asm += asm_sub
            stack.append(result_py)
        elif re.match(r'^-?\d+(\.\d+)?$', token): #numeros
            stack.append(float(token))
        elif token in "+-*/|%^": #operadores
            b = stack.pop()
            a = stack.pop()
            ai, af, sa = parse_num(str(a))
            bi, bf, sb = parse_num(str(b))

            # traduz
            asm += f"\n; --- INSTRUÇÃO {INSTR_ID} ---\n"
            asm += load_number_block(ai, af, sa, 'primary')
            asm += load_number_block(bi, bf, sb, 'secondary')
            asm += to_op_code(token) + "\n"

            # resultado em py
            try:
                r = eval(f"{a}{token}{b}") if token != '|' else a / b
            except Exception:
                r = 0
            stack.append(r)
            INSTR_ID += 1
        else:
            raise ValueError(f"invalido: {token}")
    return asm, stack[0]


def tokenize_rpn_nested(expr: str): # transforma em uma lista de tokens
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
    return stack[0]


def processar_arquivo(nome_arquivo, arquivo_base="base.asm"):
    # Carrega o código base
    with open(arquivo_base) as base_file:
        codigo_base = base_file.read()

    # Lê as expressões do arquivo
    with open(nome_arquivo) as f:
        linhas = f.readlines()

    # Bloco setup e início do main
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
    body = ""
    for idx, linha in enumerate(linhas):
        tokens = tokenize_rpn_nested(linha.strip())
        asm, result = evaluate_rpn(tokens)
        debug_output.append((linha.strip(), result))
        asm += "call send_sign_primary\ncall send_full_byte_decimal_primary\nldi r30, '|'\ncall send_char_call_no_Correction\n"
        body += asm
        body += "\n; --------------------------\n"
        body += "   clr r24\n"

    final = """
        ldi r30, 13
        call send_char_call_no_Correction
        call delay
        rjmp main"""
    
    return codigo_base + "\n" + setup + body + final



if __name__ == "__main__":

    nome_arquivo = 'file02.txt'
    base_arquivo = 'base.asm'
    assembly_code = processar_arquivo(nome_arquivo, base_arquivo)

    with open("assembly_out/saida.asm", "w") as out:
        out.write(assembly_code)
    print("resultados em py:")
    for expr, val in debug_output:
        print(f"{expr} = {val:.4f}")



