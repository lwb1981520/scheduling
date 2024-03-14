
%该类目标：
%1. 存储x->y, y->x对应关系，并快速由x找到y,y找到x
%2. 对于不在的x，如处在已有的x的某个区间内，能通过线性方式得到近似结果
classdef DiscFunc
    
    properties
        
        mapx2y;
        mapy2x;
        
        %bound_x范围内的x,返回的都是bound_x_v的值，下同
        %bound_x如是intmax，即可表明不存在bound
        bound_x;
        bound_x_v;
        
        bound_y;
        bound_y_v;
        
    end
   
    
    methods(Static)
        
        %找到最近的值
        %找到的最大的比v小的值的索引
        
        function hasv = isInRange(asc_seqs,v)
            
            len = size(asc_seqs,2);
            
            if(len < 1)
               throw(MException('range:error',sprintf('asc_seqs len is %d',len))); 
            end
            
            hasv = 0;
            
            if( v - asc_seqs(1) >= 0 && asc_seqs(len) - v >= 0 )
               hasv = 1;
            end
            
        end
        
        function idx = getNearestValue(asc_seqs,v)
            
            len = size(asc_seqs,2);
            
            if( ~DiscFunc.isInRange(asc_seqs,v) )
               throw(MException('DiscFunc:err',sprintf('%d not in range (%d %d)',v,asc_seqs(1),asc_seqs(len)))); 
            end
            
            idx1 = 1;
            idx2 = len;
            
            % 同步缩减
            while (idx2 - idx1 > 1)
                nidx = (idx1+idx2)/2;
                nidx = uint16(nidx);
                
                nv = asc_seqs(nidx);
                
                %找到索引了
                if (nv == v)
                   idx = nidx;
                   return;
                end
                
                if(nv < v)
                   idx1 = nidx; 
                else
                    idx2 = nidx;
                end
                
            end
            
            v1 = asc_seqs(idx1);
            v2 = asc_seqs(idx2);

            if(v - v1 >= 0 && v2 - v >= 0)
                idx = idx1;
            else
                throw(MException('DiscFunc:err',sprintf('%d not in range ( %d %d) ',v,v1,v2))); 
            end
            
            
        end
        
        function test()

            
           seqs =1.0:1.0:10.0;
           
           assert(DiscFunc.isInRange(seqs,0.999) == 0, 'err');
           assert(DiscFunc.isInRange(seqs,1) == 1, 'err');
           assert(DiscFunc.isInRange(seqs,5) == 1, 'err');
           assert(DiscFunc.isInRange(seqs,10) == 1, 'err');
           assert(DiscFunc.isInRange(seqs,10.0000000001) == 0, 'err');
            
            
            a = 1:0.5:10;
            
            assert(DiscFunc.getNearestValue(a,1.5) == 2, 'err');
            assert(DiscFunc.getNearestValue(a,4.5) == 8, 'err');
            assert(DiscFunc.getNearestValue(a,9.5) == 18, 'err');
           assert(DiscFunc.getNearestValue(a,4.6) == 8, 'err');
           assert(DiscFunc.getNearestValue(a,9.6) == 18, 'err');

           
           df = DiscFunc();
           
           for i=1:10;
              
               df.addxy(i,i*2);
           end
            
           
           assert(df.gety(2)==4,'err');
           assert(df.gety(8)==16,'err');
           
           assert(df.gety(2.5)==5,'err');
           assert(df.gety(8.5)==17,'err');

           
           assert(df.getx(2)==1,'err');
           assert(df.getx(8)==4,'err');
           
           assert(df.getx(2.5)==1.25,'err');
           assert(df.getx(17)==8.5,'err');
           
           
           df = df.setBoundX([1 7],0);
           df = df.setBoundY([1 9],0);
           
         
           assert(df.getx(1)==0,'err');
           assert(df.getx(2)==0,'err');
           assert(df.getx(9)==0,'err');
           
           assert(df.gety(1)==0,'err');
           assert(df.gety(2)==0,'err');
           assert(df.gety(7)==0,'err');
           
           
           assert(df.hasX(0.99) == 0, 'err');
           assert(df.hasX(1.0) == 1,'err');
           assert(df.hasX(1) == 1, 'err');
           assert(df.hasX(5) == 1, 'err');
           assert(df.hasX(10) == 1, 'err');
           assert(df.hasX(10.000) == 1, 'err');
           assert(df.hasX(10.0001) == 0, 'err');

           assert(df.hasY(1) == 1, 'err');
           assert(df.hasY(10) == 1, 'err');
           assert(df.hasY(20) == 1, 'err');
           
            display('ALL OK');
        end
        
       
        function y = getAproValue(x1,y1,x2,y2,x)
            
            yd = y2-y1;
            xd = x2-x1;
            
            nxd = x-x1;
            
            
            
            %nyd = yd * (0.415+ nxd/xd);
            nyd = yd * (nxd/xd);
            
            if (abs(nyd) - abs(yd) > 0)
               nyd = yd; 
            end
            
            y = y1 + nyd;
            
        end
        
        function y=getAproY(x,mapx2y)
            
            if(isKey(mapx2y,x))
                y = mapx2y(x); 
            else
                
                asc_seqs = sort(cell2mat(keys(mapx2y)));
                idx = DiscFunc.getNearestValue(asc_seqs,x);
                
                x1 = asc_seqs(idx);
                x2 = asc_seqs(idx+1);
                
                y1 = mapx2y(x1);
                y2 = mapx2y(x2);
                
                y = DiscFunc.getAproValue(x1,y1,x2,y2,x);
                
            end
            
        end
        
        
        
    end
    
    
    methods
        
        function self =DiscFunc()
           
            self.mapx2y = containers.Map({0},{0});
            remove(self.mapx2y,0);
            
            self.mapy2x = containers.Map({0},{0});
            remove(self.mapy2x,0);
            
            self.bound_x = [ intmax intmax ];
            self.bound_x_v = 0;
            self.bound_y = [intmax intmax];
            self.bound_y_v = 0;
            

            
            
        end
        
        function obj=setBoundX(self,a_bound_x,v)
            
            
            
            self.bound_x = a_bound_x;
            self.bound_x_v = v;
            obj = self;
        end
        
        function obj=setBoundY(self,a_bound_y,v)
            self.bound_y = a_bound_y;
            self.bound_y_v = v;
            obj = self;
            
        end
        
        %加入变量
        function obj=addxy(self,x,y)
            

            
            self.mapx2y(double(x)) = double(y);
            self.mapy2x(double(y)) = double(x);

            
            obj = self;
        end
        
        %x是否在已有的数值区间内
        function hasx = hasX(self,x)
            
            x = double(x);
            
            asc_seqs = sort(cell2mat(keys(self.mapx2y)));
            
            hasx = DiscFunc.isInRange(asc_seqs,x);
            
            if ( x - self.bound_x(1) >=0 && self.bound_x(2) - x >=0)
                
                hasx = 1;
                
            end
            
            
        end
 
        %x是否在已有的数值区间内
        function hasy = hasY(self,y)
            
            asc_seqs = sort(cell2mat(keys(self.mapy2x)));
            
            hasy = DiscFunc.isInRange(asc_seqs,y);
            
            if ( y - self.bound_y(1) >=0 && self.bound_y(2) - y >=0)
                
                hasy = 1;
                
            end
            
            
        end
        
        
        
        
        %在map中查找，若找不到，则用近似算法得到
        function y=gety(self,x)
            
            if (self.bound_x(1) <=x && x <= self.bound_x(2))
               y = self.bound_x_v; 
            
            else
                       
            y =  DiscFunc.getAproY(x,self.mapx2y);
            
            end
        end
        
        function x=getx(self,y)
            if (self.bound_y(1) <=y && y <= self.bound_y(2))
                x = self.bound_y_v; 
            
            else            
                x =  DiscFunc.getAproY(y,self.mapy2x);
            end
        end        
        
        
        
    end
    
end