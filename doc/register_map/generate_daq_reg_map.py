#!/usr/bin/python

import os
import argparse

#process a register address and its entries
def GenEntry(out_file,entries):
    if len(entries) == 0:
        return


    
    #skip multiple constants for related tables
    start_line = 2
#    print entries[start_line]
#    while entries[start_line].find("constant") != -1:
#        print "\t"+entires[start_line]
#        start_line= start_line+1
    
    reg_r = int(0)
    reg_w = int(0)
    reg_a = int(0)

    print entries[start_line]
    
    #scan each of the bit lines and record which attributes (r/w/a) they have
    for iLine in range(start_line,len(entries)):
        line = entries[iLine].split()
        if len(line) > 1:
            #handle simple lines with one bit on them
            if line[1].find("..") == -1:                
                mask = 1 << int(line[1])        
                if line[2].find("r") != -1:
                    reg_r = (reg_r & ~mask) + mask
                if line[2].find("w") != -1:
                    reg_w = (reg_w & ~mask) + mask
                if line[2].find("a") != -1:
                    reg_a = (reg_a & ~mask) + mask
            #handle lines that have bit ranges in them.
            else:
                sub_line = line[1].split("..")
                low_bound = min(int(sub_line[1]),int(sub_line[0]))
                high_bound = max(int(sub_line[1]),int(sub_line[0]))+1
                for ibit in range(low_bound,high_bound):
                    mask = 1 << ibit        
                    if line[2].find("r") != -1:
                        reg_r = (reg_r & ~mask) + mask
                    if line[2].find("w") != -1:
                        reg_w = (reg_w & ~mask) + mask
                    if line[2].find("a") != -1:
                        reg_a = (reg_a & ~mask) + mask

    #Start the first line with the register name (removing the "_" marks)
    latex_line = entries[0].replace('_',' ') + " & "
    #add the hex address in the second column
    latex_line = latex_line + hex(int("0"+entries[1].replace('"','').replace(';',''),16))
    # add the color coded bit fields
    for iBit in range(31,-1,-1):
        mask = 0x1 << iBit
        latex_line = latex_line + " & "
        if (reg_r & mask == mask) and (reg_w & mask == mask):
            latex_line = latex_line + "\\cellcolor{cyan} "
        elif (reg_r & mask == mask) and (reg_a & mask == mask):
            latex_line = latex_line + "\\cellcolor{yellow} "
        elif (reg_r & mask == mask):
            latex_line = latex_line + "\\cellcolor{green} "
        elif (reg_w & mask == mask):
            latex_line = latex_line + " \\cellcolor{blue} "
        elif (reg_a & mask == mask):
            latex_line = latex_line + " \\cellcolor{red} "
        latex_line = latex_line + " " + str(iBit)
    latex_line = latex_line + " \\\\ \\hline\n"
    out_file.write(latex_line)
    #add each bit with its description on the next line
    for iLine in range(start_line,len(entries)):
        line = entries[iLine].split()
        
        latex_line = (" & " + " ".join(line[1:3]) + " &  \\multicolumn{32}{|l|}{" + " ".join(line[3:]) + "} \\\\ \\hline\n").replace('_',' ')
        out_file.write(latex_line)

    
    print entries[0], hex(reg_r)[2:].zfill(8), hex(reg_w)[2:].zfill(8), hex(reg_a)[2:].zfill(8)










parser = argparse.ArgumentParser(description='Generate latex register map')

parser.add_argument('file', type=str, help='input vhdl file')
args = parser.parse_args()



vhdl_file = open(args.file)
lines = vhdl_file.readlines()

#open the output file
out_file_name = os.path.basename(args.file)
if out_file_name.find('.vhd') == -1:
    out_file_name = out_file_name + ".tex"
else:
    out_file_name = out_file_name.replace('.vhd','.tex')
print out_file_name
out_file = open(out_file_name,'w+')


startLine = 0
endLine = len(lines)

iLine = 0
while iLine < len(lines):
    if lines[iLine].find("-- Address space") != -1:
        startLine = iLine
    if lines[iLine].find("-- Signals") != -1:
        endLine = iLine
        break
    iLine = iLine + 1

#out_file.write( "\\documentclass{standalone}\n")
out_file.write( "\\documentclass[landscape,margin=3pt,pstricks]{standalone}\n")
out_file.write( "\\usepackage{color}\n")
out_file.write( "\\usepackage{colortbl}\n")
out_file.write( "\\begin{document}\n")
out_file.write( "\\setlength{\\tabcolsep}{1.45pt}\n")
out_file.write( "% This sets 32 centered fields\n")
out_file.write( "\\begin{tabular}{|c|c|*{32}{c|}}  \n")
out_file.write( "  \\hline\n")
out_file.write( " Register & address & \multicolumn{32}{|c|}{} \\\\ \\hline\n")


row = []
iLine = startLine
line_number = 0
while iLine < endLine:
#for iLine in range(startLine,endLine):
    line = lines[iLine]

    #initial guess of next line to process
    iLineEnd = iLine + 1
    #look for the start of an entry
    if line.find("constant") != -1:
        #found a constant line
        
        #start row magic from this line
        row = [line.split()[1],line.split()[7]]

        #skip over any following constant lines (fix later to make entries for these as well)
        iLineStart = iLine+ 1
        while (lines[iLineStart].find("constant") != -1):
            iLineStart = iLineStart + 1
        if len(lines[iLineStart]) > 0:
            row.append(lines[iLineStart])
        #find the line after all description lines
        iLineEnd = iLineStart
        while (lines[iLineEnd].find("----") == -1):
            iLineEnd = iLineEnd + 1
            if len(lines[iLineEnd]) > 0:
                row.append(lines[iLineEnd])
        #row is now has all the data for an entry
        GenEntry(out_file,row)

    #this line moves to the next entry.
    #because I thought this out beforehand (magic) if you don't do this, it will make entries for repeated substructures.
    #this is very cool, but make large files that are not strictly ordered by address
    iLine = iLineEnd


    line_number = line_number + 1
    if line_number > 20:
        line_number = 0
        out_file.write("  \\hline\n")
        out_file.write("\\end{tabular}\n")
        out_file.write("\\newpage")
        out_file.write( "\\begin{tabular}{|c|c|*{32}{c|}}  \n")
        out_file.write( "  \\hline\n")
        out_file.write( " Register & address & \multicolumn{32}{|c|}{} \\\\ \\hline\n")

    
#    if line.find("constant") != -1:
#        GenEntry(out_file,row)
#        row = [line.split()[1],line.split()[7]]
#    elif len(row) > 0:
#        if line.find("----") > 0:
#            GenEntry(out_file,row)
#            row = []
#        else:
#            row.append(line)

out_file.write("  \\hline\n")
out_file.write("\\end{tabular}\n")
out_file.write("\\end{document}\n")
