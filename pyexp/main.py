'''
Created on 27 set 2022

@author: emilio
'''

import subprocess
import xml.etree.ElementTree as ET
import numpy as np
from numpy import dtype

if __name__ == '__main__':
    
    nexp = 1;
    e = [];
    S = np.zeros([nexp, 3]);
    nclients = np.zeros([nexp, 1]);
    runtime = np.zeros([nexp, 1]);
    
    JMTres=np.zeros([nexp, 4])
    LQNSres=np.zeros([nexp, 4])
    
    
    for i in range(nexp):
        nclients[i,0]=np.random.randint(low=100,high=300,dtype=int);
        S[i,:]=np.random.randint(low=1,high=10,size=[1,3],dtype=int);
        
        #solve JMT model
        tree = ET.parse('../lqnsExp/jmtTpl.jmva')
        root = tree.getroot()
        
        classes=root.find("parameters").find("classes")
        for c in classes:
            if(c.attrib["name"]=="Class1"):
                c.attrib["population"]="%d"%int(nclients[i,0])
                
        stations=root.find("parameters").find("stations").findall("listation")
        for st in range(len(stations)):
            stations[st].attrib["servers"]="%d"%(S[i,st])
        
        tree.write('jmtModel.jmva');
        subprocess.check_call(["java","-cp","/Applications/JMT-1.1.1.jar","jmt.commandline.Jmt", "mva",
                               "jmtModel.jmva"]);
        
        tree = ET.parse('jmtModel.jmva-result.jmva')
        root = tree.getroot()    
        
        solutions=root.find("solutions")
        for alg in solutions.findall("algorithm"):
            if(alg.attrib["name"]=="MVA"):
                results=alg.findall("stationresults")
                rt=[]
                for res in results:
                    #print(res.attrib["station"])
                    measures=res.find("classresults").findall("measure")
                    for m in measures:
                        if(m.attrib["measureType"]=="Residence time"):
                            rt.append(m.attrib["meanValue"])
                    
                JMTres[i,:]=rt
        
        #devo aggiungere la soluzione del sistema lineare
        
        #difflqn
        fid=open("../lqnsExp/simple-qn.lqn","r")
        lansTpl=fid.read()
        fid.close();
        
        lqnModel=None
        keys=["$P1","$P2","$P3","$P4","$T1","$T2","$T3","$T4"]
        lansTpl=lansTpl.replace("$P1","%d"%int(nclients[i,0]*10))
        lansTpl=lansTpl.replace("$T1","%d"%int(nclients[i,0]))
        lansTpl=lansTpl.replace("$T2","%d"%int(nclients[i,0]*10))
        lansTpl=lansTpl.replace("$T3","%d"%int(nclients[i,0]*10))
        lansTpl=lansTpl.replace("$T4","%d"%int(nclients[i,0]*10))
        lansTpl=lansTpl.replace("$P2","%d"%int(S[i,0]))
        lansTpl=lansTpl.replace("$P3","%d"%int(S[i,1]))
        lansTpl=lansTpl.replace("$P4","%d"%int(S[i,2]))
        
        fid=open("lqnsModel.lqn","w+")
        fid.write(lansTpl)
        fid.close()
        
        subprocess.check_call(["java","-jar","/Users/emilio/Desktop/DiffLQN_0.1/DiffLQN.jar","lqnsModel.lqn"]);
        
        DiffLqn_data=np.genfromtxt('lqnsModel.csv',delimiter=',')
        LQNSres[i,:]=DiffLqn_data[-4:,3]
        
        #lqnsSolve
        subprocess.check_call(["lqns","--exact-mva","lqnsModel.lqn"]);
        
        
       
        print("DiffLqn",LQNSres)
        
        P2=np.matrix([[0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1],
        [0, 0, 0, 0]]);
        
        x = np.linalg.solve(np.eye(P2.shape[0])-P2,JMTres[i,:])
        
        print("JMT", JMTres)
        print("JMT2", x)
        