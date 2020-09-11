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
<b>CNN_emotions</b>: neural network implemented in python (through jupyter-notebook, a tool that allows us to visualize the code compilation step by step). This network is composed of 3 convolutional layers, followed by a dense layer. It was trained with 600 recordings of people speaking under 3 emotions: fear, sadness and happiness (see the [TESS Toronto emotional speech set data](https://www.kaggle.com/ejlok1/toronto-emotional-speech-set-tess)). After training, given any audio, this network makes predictions under which emotion the audio most fits.


<b>Notices\\_crawler</b>: this crawler (based on scrapy/python) is responsible for collecting the latest news contained in the [g1 website](https://g1.globo.com/politica/). It updates according to a delay that you can edit. note that the notices information are stored in a text file ( './data_saved/notices_info.json' ).


<b>Osc_server</b>: the osc server is responsible for waiting for processing_app to send the file name of the recorded audio. After that, it makes predictions from the CNN model that is already loaded, and sends the predictions (using the pattern: "name_emotion - %_predicao_medo - %_predicao_alegre - %_predicao_triste") for processing app.


<b>Processing_app:</b> this is the main app. Here we load the notices collected from crawler, print it in a interface. After choose one notice, the app starts the webcam and start to record audio time per time, sending the name of the recorded audio by osc to osc_server. After receives the prediction information, print it in the screen.




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



<b>IMPORTANT</b>
Check variables of all modules (osc_server, notices_crawler and processing_app).
In especial, to run, you only need to change crawler_path in processing code.



<b>NOT NECESSARY</b>

All variables can be edited, like time to update notices, time to record the sounds, link for crawling notices, ip and port of the osc communication.


If you need to read and see the CNN's functioning...


You'll need install the [jupyter-notebook framework](https://jupyter.org/install) to read the CNN code (note that you don't need compile CNN to run the app, since it has already been trained and the OSC_server just reloads the model to make predictions).



Usage
------

The code is fully commented, any questions please look at contact information at the bottom of this page.


Initially we must turn on the crawler to collect news from time to time. If you're in the main directory of this project, just type:

```python
scrapy runspider ./notices_crawler/main.py 
```


Note that if the crawler is not started, the application will collect news from the last date I used this project.
Right after starting the crawler (optional), we will turn on the OSC server that will be waiting for the names of the audios to be predicted:

```python
python3.6 ./osc_server/main.py
```


Then just open the processing app at './processing_app/processing_app.pde' and click start to compile and enjoy the application! :D



additional information
-----------------------


audio n está completo, mas pode ser obtido em
note que utilizei apenas 3 tipos de emoçoes
ruidos podem dar muito ruim


melhorias que podem ser realizadas:
max_pad_len tirar todos os 0's
aumentar o dataset (tanto em tamanho quanto em classes)
unificar o crawler
testar outros descritores de áudio
tratar conflito do crawler com o app, as vezes ele atualiza no momento em que o app vai ler as notices info

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
