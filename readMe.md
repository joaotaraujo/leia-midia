Leiamidia
====================


About
------
The Brazilian political dispute has intensified recently and within this intensification the dispute for the media space has become a central point of debate that involves both right and left. 
It is common to find criticism within both political spectra related to the partiality of the media when a news story is broadcast live in the TV newspaper. 
But is it possible to read a news item so as not to convey a feeling? 

In this installation, called Leiamídia, the participant is invited to be the anchor of a news program and to read a news recently published in a news portal. 
The anchor's voice is then processed by a neural network that will classify it in relation to the feeling it conveys. 
How much joy or sadness or fear can you transmit by reading a text? Read media and try to be impartial.

#You can see an example of the app in [in comming](https://www.youtube.com/channel/UCvXRe3UjqHNDnKvTpAOLyeA/featured).


Files
-----
<b>CNN_emotions</b>: 



based on [TESS Toronto emotional speech set data](https://www.kaggle.com/ejlok1/toronto-emotional-speech-set-tess)


<b>notices-crawler</b>

<b>osc_server</b>
<b>processing_app</b>


Requirements
-----------------
To run the application, you must have <b>python 3</b> installed in your machine (for CNN, notice_crawler and OSC_server). 


After, install the following packages using <b>pip install</b> or another package manager (i may have forgotten a module :D , but the ones that are missing can be viewed when OSC_server is compiled):

* numpy
* matplotlib
* librosa 
* pandas
* sklearn
* keras
* scrapy
* news-please




You need to download [Processing](https://processing.org/download/) API to run main application.
Open <b>./processing_app/processing_app.pde</b> and check if all imports are ok.
If not, try to slice all <b>./processing_app/code/*.jar</b> to processing code screen (it will force the linking of the jar's into project).






<b>NOT NECESSARY</b>

if you need to read and see the CNN's functioning...

You'll need install the <b>[jupyter-notebook framework]</b>(https://jupyter.org/install) to read the CNN code (note that you don't need compile CNN to run the app, since it has already been trained and the OSC_server just reloads the model to make predictions).



Usage
------





additional information
-----------------------

mudar diretorios
variáveis

audio n está completo, mas pode ser obtido em
note que utilizei apenas 3 tipos de emoçoes


funcionamento
--------------


Contact
--------

<b>Email: teixeira.araujo@gmail.com</b>

<b>Our research group (ALICE Arts Lab):</b> [https://alice.dcomp.ufsj.edu.br/](https://alice.dcomp.ufsj.edu.br/)













AFAZER

atualizar em tempo real
colocar author nome no app processing
botão voltar
tirar import desnecessario do processing
