import sys
import re


def readFile():
    with open(sys.argv[1], 'r') as file:
        return [line.strip() for line in file.readlines()]

def separateOperation(string):
    match = re.match(r"\((.*?)\)", string)
    if match:
        return match.group(1).split()
    return []

def hasNested(string): # Checa se não existem operações aninhadas
    stack = []
    for char in string:
        if char == "(":
            stack.append(char)
        elif char == ")":
            if len(stack) > 1:
                return True
    return False

def doOperation():
    pass

def buildCmdString():
    pass

def main():
    
    file = readFile()

    oper = separateOperation(file[9])

    print(hasNested(file[9]))


    pass

main()