
%记录ERP结果


function lab2_1()

outf='lab2_1_out.txt';
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
      
           afrp.TAR_traf = uint16(t_total * 1.5);
           
           afrp = afrp.setup();

           [sLi sLij sReven collector] = afrp.solveSSP();
   
           
           
           %输出
           o_begin = ceil(t_total/2);
           o_end = ceil(t_total*1.5);
           o_step = ceil(t_total/10);
           
           for otraf = o_begin:o_step:o_end
           
               resu = collector.getByU(otraf);
               sReven = afrp.getRevenue(resu.Li,resu.Lij);

               res_str = sprintf('%d\t%d\t%f\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f',afrp.I,afrp.J,afrp.zipf,afrp.total,otraf,0,0,sReven,0,0,0);

               display(res_str);
               fprintf(fid,'%s\n',res_str);
            
           end

    sfname = sprintf('%s/LAB2_1_I%d_J%d_Z%f_TO%d_TRF%d_TR2F%d.frp','matfiles',afrp.I,afrp.J,afrp.zipf,afrp.total,afrp.TAR_traf,afrp.TAR_traf2frp);
    save(sfname, 'afrp','-mat');
    display(sprintf('frp saved to file %s',sfname));
    
    
   end
    
end

fclose(fid);


end




           
           
           
