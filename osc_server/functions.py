#########################################################################################################################################
############################################################ functions ##################################################################
#                                                                                                                                       # 
#			-	extract_features(self, file_name): read audio file (based on full path), apply mfcc and return the coefficients                   #
#			-	get_prediction(self, file_name): process audio file and apply model predict                                                       #
#			-	send_msg_osc(self, tag, value): send predicted information via OSC                                                                #
#			-	process_osc_msg(self, unused_addr, args, fileName): get audio file name via OSC, process it, and send the predicted information   #
#			-	startListening(self): put server to wait for OSC messages                                                                         #
#                                                                                                                                       #
#########################################################################################################################################



############################################################# imports ####################################################################

# for file/data manipulating
from os import listdir
from os.path import isfile, join
from keras.models import model_from_json
import pandas as pd	
import numpy as np

# for MIR functions
import librosa
from sklearn.preprocessing import LabelEncoder
from keras.utils import to_categorical

# to extract notices information 
from newsplease import NewsPlease

# for time functions
import time
import datetime

# for OSC functions
from pythonosc import dispatcher
import argparse
from pythonosc import osc_server
from pythonosc import udp_client


########################################################## server main class #################################################################

class OSC_server:

				# constructor to set self variables and start listening
				def __init__(self, n_mfcc, max_pad_len, num_channels, ip, server_port, client_port):

								self.soundPath = "../processing_app/sounds/"
								self.n_mfcc = n_mfcc
								self.max_pad_len = max_pad_len
								self.num_channels = num_channels
								self.ip = ip
								self.server_port = server_port
								self.client_port = client_port

								# load json and create model
								json_file = open('../CNN_emotions/model_saved/model.json', 'r')
								loaded_model_json = json_file.read()
								json_file.close()
								loaded_model = model_from_json(loaded_model_json)

								# load weights into new model
								loaded_model.load_weights("../CNN_emotions/model_saved/model.h5")
								self.model = loaded_model

								# load features to use to get classes
								self.featuresdf = pd.read_pickle('../CNN_emotions/data_processed/featuresData')    

								self.dispatcher = dispatcher.Dispatcher()
								self.startListening()
								

				############################################################# MIR functions ####################################################################
				#---------------------------------------------------------------------------------------------------------------------------------------#
				# this function load the audio and pick their features
				def extract_features(self, file_name):

						try:
								print("\n\n\n\n",file_name)
								# get the audio vector and the sample rate
								y, sr = librosa.load(file_name, res_type='kaiser_fast') 

								# get mfcc's vector
								mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=self.n_mfcc)

								# adjust the size of each audio, according to max_pad_len
								if(mfccs.shape[1]>self.max_pad_len):
										mfccs = mfccs[:,:self.max_pad_len]
								else:
										pad_width = self.max_pad_len - mfccs.shape[1]
										mfccs = np.pad(mfccs, pad_width=((0, 0), (0, pad_width)), mode='constant')

						except Exception as e:
								print("Error encountered while parsing file: ", file_name)
								return None 

						return mfccs



				#---------------------------------------------------------------------------------------------------------------------------------------#
				# function to classify the audio
				def get_prediction(self, file_name):

								# extract audio features
								prediction_feature = self.extract_features(self.soundPath + file_name) 

								# format input < 1, num_rows, num_columns, num_channels >
								prediction_feature = prediction_feature.reshape(1, self.n_mfcc, self.max_pad_len, self.num_channels)

								# predic the class
								predicted_vector = self.model.predict_classes(prediction_feature)

								# codify the label
								y = np.array(self.featuresdf.class_label.tolist())
								le = LabelEncoder()
								yy = to_categorical(le.fit_transform(y)) 

								# get predictions
								predicted_class = le.inverse_transform(predicted_vector) 
								predicted_proba_vector = self.model.predict_proba(prediction_feature) 
								predicted_proba = predicted_proba_vector[0]

								print("The predicted class is:", predicted_class[0])

								# get the % chance of each class
								for i in range(len(predicted_proba)): 
												
												category = le.inverse_transform(np.array([i]))
												
												print(category[0], "\t : ", format(predicted_proba[i], '.16f') )
																
								print('\n\n')

								return predicted_class[0], predicted_proba


				########################################################## OSC functions ################################################################
				#---------------------------------------------------------------------------------------------------------------------------------------#
				# function to send the osc message
				def send_msg_osc(self, tag, value):

								# set the ip and port
								parser = argparse.ArgumentParser()
								parser.add_argument("--ip", default=self.ip,
								help="The ip of the OSC server")
								parser.add_argument("--port", type=int, default=self.client_port,
								help="The port the OSC server is listening on")
								args = parser.parse_args()

								# create the UDP cliente and send the message
								client = udp_client.SimpleUDPClient(args.ip, args.port)
								client.send_message(tag, value)



				#---------------------------------------------------------------------------------------------------------------------------------------#
				# function to get msg from client UDP, predict the class name, put it in format (predictionName-%ofFear-%ofHappy-%ofSad) and send via OSC
				def process_osc_msg(self, unused_addr, args, fileName):

								print("Message received: ", fileName)
        
								predicted_class, predicted_proba = self.get_prediction(fileName)
								oscMsg = "{}-{:.2f}-{:.2f}-{:.2f}".format(predicted_class, predicted_proba[0]*100, predicted_proba[1]*100,   predicted_proba[2]*100)
								print("Sending OSC msg: ", oscMsg)
								# update notices hour per hour
								now = datetime.datetime.now()
								print("Done ( ", now.hour, "h : ", now.minute, "m : ", now.second, "s )!")

								self.send_msg_osc("/prediction", oscMsg)





				#---------------------------------------------------------------------------------------------------------------------------------------#
				# function to put the server waiting for msg's
				def startListening(self):

								# starts the server
								parser = argparse.ArgumentParser()
								parser.add_argument("--ip", default=self.ip, help="The ip to listen on")
								parser.add_argument("--port", type=int, default=self.server_port, help="The port to listen on")
								args = parser.parse_args()

								self.dispatcher.map("/fileName", self.process_osc_msg, "fileName")

								server = osc_server.ThreadingOSCUDPServer((args.ip, args.port), self.dispatcher)
								print("Serving on {}".format(server.server_address))

								server.serve_forever()



		
