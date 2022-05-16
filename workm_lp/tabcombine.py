#!/usr/bin/python
# This script combines multiple outreg .tex files into a single table.
#import re
import json

with open("nicenames_d.json", "r") as fp:
    nicenames = json.load(fp)

def make_tex_table(varlist, rhsspecs, sourcedir, outfilename):
    """Combine multiple outreg .tex files into a latex table."""

    outtable = "\\\\"

    for var in varlist:
        outtable += '\\midrule\n' + nicenames.get(var, var) + '\\\\\n'
        
        for rhsspec in rhsspecs:
            
            with open(sourcedir + '/' + var + '-' + rhsspec + '.tex') as f:
                lst = f.readlines()
            for line in lst[1:]:
                if rhsspec.startswith('z_') and line.startswith('Ftest'):
                    continue
                else:
                    outtable += line
            outtable += '\\\\\n'
            
            if rhsspec=='pm':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (simple)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (simple)')
            elif rhsspec=='median':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (median rotation)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (median rotation)')
            elif rhsspec=='q25':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (pct25 rotation)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (pct25 rotation)')
            elif rhsspec=='q75':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (pct75 rotation)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (pct75 rotation)')
            elif rhsspec=='q10':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (pct10 rotation)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (pct10 rotation)')
            elif rhsspec=='q90':
                outtable = outtable.replace('b1','$\\beta^{MP}_h$ (pct90 rotation)')
                outtable = outtable.replace('b2','$\\beta^{CBI}_h$ (pct90 rotation)')
            else:
                outtable = outtable.replace('b1','$\\beta_h$')

    outtable = outtable.replace('s1','')
    outtable = outtable.replace('s2','')
    outtable = outtable.replace('Ftest','F-test')

    with open(outfilename, "w") as out_file:
        out_file.write(outtable)

if __name__ == '__main__':

    #ECB
    shockspec = "ecb_mpd_me_njt"
    sourcedir = shockspec + ""
        
    rhsspecs = ['median', 'pm']
    varlist = ['sveny01_d','bund1y_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks1a.txt')

    rhsspecs = ['q25', 'q75']
    varlist = ['sveny01_d','bund1y_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks1b.txt')

    rhsspecs = ['q10', 'q90']
    varlist = ['sveny01_d','bund1y_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks1c.txt')

    rhsspecs = ['surp']
    varlist = ['bund1y_d','sveny01_d','bund10y_d','sveny10_d','stoxx50_d','sp500_d',
                'bofaml_ea_hyld_oas_d','bofaml_us_hyld_oas_d','eurusd_d','broadexea_usd_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbsurp1.txt')

    rhsspecs = ['median', 'pm']
        
    varlist = ['sveny10_d','sp500_d','bofaml_us_hyld_oas_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks2.txt')

    varlist = ['logvix_d','eurusd_d','broadexea_usd_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks3.txt')
    
    # ECB -> stock subindices
    varlist = ['sp500geo_eu0w_d', 'sp500geo_us0w_d', 'sp500geo_eu0wus0w_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks-stocks1.txt')
    
    varlist = ['sp500fin_d', 'sp500exfin_d', 'spr_sp500_finexfin_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks-stocks2.txt')
    
    varlist = ['willsmlcap_d', 'willlrgcap_d', 'spr_will_smllrgcap_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-ecbshocks-stocks3.txt')
   
    # Fed
    shockspec = "fed_gssipa_me_99njt"
    sourcedir = shockspec + ""
    
    rhsspecs = ['median', 'pm']
    
    varlist = ['bund1y_d','bund10y_d','stoxx50_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-fedshocks1.txt')

    varlist = ['bofaml_ea_hyld_oas_d','eurusd_d','broadexea_usd_d']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-fedshocks2.txt')
   
    
    # EA macro surprises -> US variables
    sourcedir = "macro_releases"
    varlist = ['sveny01_d','sveny10_d','sp500_d',
                'bofaml_us_hyld_oas_d','eurusd_d','broadexea_usd_d']
    # varlist = ['bund1y_d','sveny01_d','bund10y_d','sveny10_d','stoxx50_d','sp500_d',
    #             'bofaml_ea_hyld_oas_d','bofaml_us_hyld_oas_d','eurusd_d','broadexea_usd_d']
    rhsspecs = ['z_ea_bcs_confind']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-'+rhsspecs[0]+'.txt')
    rhsspecs = ['z_ea_unemp']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-'+rhsspecs[0]+'.txt')

    # EA macro surprises -> stocks  
    varlist = ['sp500geo_eu0w_d', 'sp500geo_us0w_d', 'sp500geo_eu0wus0w_d']
    varlist += ['sp500fin_d', 'sp500exfin_d', 'spr_sp500_finexfin_d']
    varlist += ['willsmlcap_d', 'willlrgcap_d', 'spr_will_smllrgcap_d']
    rhsspecs = ['z_ea_bcs_confind']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-'+rhsspecs[0]+'-stocks.txt')
    rhsspecs = ['z_ea_unemp']
    make_tex_table(varlist, rhsspecs, sourcedir, 'table-'+rhsspecs[0]+'-stocks.txt')
