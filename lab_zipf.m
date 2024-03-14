




outf='lab_zip_out.txt';
fid=fopen(outf,'w');
t_total = 1000;

for t_zipf = 0.6:0.1:1.4

    afrp = FrpLab();
    afrp.total = t_total;

    afrp.I = 500;
    afrp.J = 4;

    afrp.zipf = t_zipf;           
    afrp = afrp.setup();  
    
    %TODEL
    afrp.flow_inc = 1;
    
    afrp.TAR_traf = 1.5*t_total;
    
    [sLi sLij sReven collector] = afrp.solveSSP();
           
    for t_traf = 0.5*t_total:0.5*t_total:1.5*t_total %100:100:200 %
       
           %可用资源是TAR_traf
           afrp.TAR_traf = t_traf;
           %这里mReven就是均值的revenue了
           [mLi mLij mReven] = afrp.solveMean();        
           
           %display(sprintf('(!)MEAN: T%f %f %f ',t_traf,sum(mLi),sum(sum(mLij,1))) );
         for prec = [100] %[2 4 8 16 32 64 128] %[10 50 100] %[10 20 40] % 
           
           afrp.TAR_traf2frp = prec;
     
           %这里fReven是d-urp的revenue了
           
           [fLi fLij fReven] = afrp.solveFrp();
           
           %resu包含了SSP方法的，对给定t_traf的所有结果
           
           
           resu = collector.getByU(t_traf);
           sReven = afrp.getRevenue(resu.Li,resu.Lij);
           
           res_str = sprintf('%d\t%d\t%f\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f',afrp.I,afrp.J,afrp.zipf,afrp.total,afrp.TAR_traf,afrp.TAR_traf2frp,mReven,sReven,fReven,sum(fLi),sum(sum(fLij,1)));
           
           display(res_str);
           fprintf(fid,'%s\n',res_str);
 
%sfname = tm.getsname('data');

%if(exist(sfname) == 2)
% if (1 > 2)
%     clear tm;
%     display(sprintf('TM loaded from file %s',sfname));
%     load(sfname,'-mat');
%     
% else


    
    
%end
           
           
           
         end
        


    sfname = sprintf('%s/I%d_J%d_Z%f_TO%d_TRF%d_TR2F%d.frp','matfiles',afrp.I,afrp.J,afrp.zipf,afrp.total,afrp.TAR_traf,afrp.TAR_traf2frp);
    save(sfname, 'afrp','-mat');
    display(sprintf('frp saved to file %s',sfname));    
       
    end
    
    
end

fclose(fid);




           
           
           
