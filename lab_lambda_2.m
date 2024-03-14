
%记录ERP结果


function lab2_2()

outf='lab2_2_out.txt';
fid=fopen(outf,'w');

for t_zipf = [1.0]
   for t_total = [1000 5000 10000]
       
       
             %!!!!!!!!!!TODO:
            
           afrp = FrpLab();
           afrp.total = t_total;
           
           
           afrp.flow_inc = 1; %ceil(t_total/1000);
           
           afrp.I = 100;
           afrp.J = 4;
           
           afrp.zipf = t_zipf;           
      
           
    %下面计算       
    for t_traf_k = 1:3 %100:100:200 %
       
        
           %总共请求是total

           %可用资源是TAR_traf
           afrp.TAR_traf = t_traf_k * t_total /2 ;

           afrp = afrp.setup();           
           
           
           [mLi mLij mReven] = afrp.solveMean();        
           
           %display(sprintf('(!)MEAN: T%f %f %f ',t_traf,sum(mLi),sum(sum(mLij,1))) );
 
           %sReven = 0;
           

           
        for prec = [10] %20:20:200 
           
            afrp.TAR_traf2frp = prec;

            [fLi fLij fReven kp] = afrp.solveFrp();

            res_str = sprintf('%d\t%d\t%f\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f',afrp.I,afrp.J,afrp.zipf,afrp.total,afrp.TAR_traf,afrp.TAR_traf2frp,mReven,kp,fReven,sum(fLi),sum(sum(fLij,1)));

            display(res_str);
            fprintf(fid,'%s\n',res_str);

            sfname = sprintf('%s/I%d_J%d_Z%f_TO%d_TRF%d_TR2F%d.frp','matfiles',afrp.I,afrp.J,afrp.zipf,afrp.total,afrp.TAR_traf,afrp.TAR_traf2frp);
            save(sfname, 'afrp','-mat');
            display(sprintf('frp saved to file %s',sfname));
        end
        
    end
   end
    
end

fclose(fid);


end




           
           
           
