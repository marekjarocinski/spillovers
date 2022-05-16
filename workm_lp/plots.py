# Create a latex file that includes all pdfs from folder 'pdfdir'
import os
import glob
import datetime

tex_code = r"""\documentclass[11pt]{article}
\usepackage{amssymb}
\usepackage{amsfonts}
\usepackage{amsmath}
\usepackage{graphicx}
\usepackage[round]{natbib}
\usepackage{verbatim}
\usepackage{fancyhdr}
\usepackage{booktabs}
\usepackage[hmargin=0.5cm,vmargin=2cm]{geometry}
\begin{document}
\pagestyle{fancy}
\fancyhead[C]{\today}
\fancyfoot[C]{\thepage}
\noindent"""

pdfdir = 'macro_releases_sp500geo'

outtex_fname = pdfdir + ".tex"
if os.path.isfile(outtex_fname):
	os.remove(outtex_fname)

newline = True
for pdfpath in glob.glob(pdfdir + "/*.pdf"):
    fname = os.path.splitext(os.path.basename(pdfpath))[0]
    tex_code += '\\includegraphics[width=0.45\\textwidth]{' + pdfpath.replace("\\","/") + '}\n'
    newline = not(newline)
    if newline:
        tex_code += '\\\\[3ex]\n'

tex_code += '\end{document}'

tex_file = open(outtex_fname,'w')
tex_file.write(tex_code)
tex_file.close()

os.system('texify -c -p ' + outtex_fname)

