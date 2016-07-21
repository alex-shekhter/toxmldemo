# toxmldemo

Small demo project which is written in GO and using 
[NEX](https://github.com/blynn/nex) (improved LEX written in GO) and YACC approach
to parse and convert to XML hierarchial data with the following format:

```
AmpQueryRepChoice {

   tradeRep {                                   

      tradeId {                                 
         tradeNo = 20160711-000000060000
         speedIndex = -1 
         \{\}
         fake1 = 123
         fake2 =
      }
      p1 = 098
      p2 = SDF
      p3 =
      p4 = RTY 
GHT
FRE
      statics {                                 
         chainId = 1                            
         buyOrderId {                           
            orderDate = 20160711                
            orderNo = 936                       
         }
         gol1 = qwdef
         gol2 = fsdsfsfsfsffs
         sellOrderId {                          
            so1 = 11111                         
            2222
            so2 =                               
         }
         gol3 = asdrethheaw
      }
   }
}
```

As you can see value of the properties can have many **"words"** which can be 
located on the different lines. There is no special delimiter to mark end 
of the property's value.

To use converter:

```
./toxmldemo <testdata/test.txt | xmllint --format -
```


Formatted XML, generated from the data above:

```xml
<?xml version="1.0"?>
<AmpQueryRepChoice>
  <tradeRep>
    <tradeId>
      <tradeNo>20160711-000000060000</tradeNo>
      <speedIndex>-1 \{\}</speedIndex>
      <fake1>123</fake1>
      <fake2/>
    </tradeId>
    <p1>098</p1>
    <p2>SDF</p2>
    <p3/>
    <p4>RTY GHT FRE</p4>
    <statics>
      <chainId>1</chainId>
      <buyOrderId>
        <orderDate>20160711</orderDate>
        <orderNo>936</orderNo>
      </buyOrderId>
      <gol1>qwdef</gol1>
      <gol2>fsdsfsfsfsffs</gol2>
      <sellOrderId>
        <so1>11111 2222</so1>
        <so2/>
      </sellOrderId>
      <gol3>asdrethheaw</gol3>
    </statics>
  </tradeRep>
</AmpQueryRepChoice>

```

