from LanguagePrinter import LanguagePrinter

type_mappings = {
    'BinNums.coq_Z': 'int'
}


def convert_type(t):
    global type_mappings
    res = type_mappings.get(t)
    if res:
        return res
    else:
        return t


class CPrinter(LanguagePrinter):
    def __init__(self, outfile):
        super(CPrinter, self).__init__(outfile)
        self.writeln('// This C file was autogenerated from Coq')
        self.end_decl()

    def end_decl(self):
        self.writeln('')

    def type_alias(self, name, rhsName):
        self.writeln('#define {} {}'.format(name, convert_type(rhsName)))
        self.end_decl()

    def enum(self, name, valueNames):
        self.writeln('enum ' + name + ' {' + ', '.join(valueNames) + '};')
        self.end_decl()