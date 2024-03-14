           afrp = FrpLab();
           
           afrp.I = 64;
           afrp.J = 4;
           
           afrp.zipf=0.6;
           %总共请求是total
           afrp.total = 100;
           %可用资源是TAR_traf
           afrp.TAR_traf = 200;
           afrp.TAR_traf2frp = 100;
           
           afrp = afrp.setup();
           
           
        
           [sLi sLij sReven] = afrp.solveSSP();
            
           
           
           [fLi fLij fReven] = afrp.solveFrp()
           
           [mLi mLij mReven] = afrp.solveMean()
           
           
           
