#################################################################################
################################# OSC server ####################################
#                                                                               #
#  1 - get (via OSC) the name of sound that will be processed                   #
#  2 - process sound with librosa mfcc                                          #
#  3 - send predict via OSC in pattern: predictionName-%ofFear-%ofHappy-%ofSad  #
#                                                                               #
#  OBS: to run type: python3.6 ./main.py                                        #
#                                                                               #
#  Author: João Teixeira Araújo                                                 #
#                                                                               #
#################################################################################


######################################### imports ###############################################

# implemented functions - read ./functions.py in this directory
import functions as fc

#################################### setting variables ##########################################


# set the parameters
# max_pad_len is the number of columns in features audio matrix ( see in '../CNN_emotions/feature_extract.ipynb' to get this number )
max_pad_len = 174
num_columns = max_pad_len


# num_rows in features audio matrix equals to number of mfcc's coeficients, 
# it need to be the same number used in CNN's audio training ( see in '../CNN_emotions/feature_extract.ipynb' to get this number )
n_mfcc = 40
num_rows = n_mfcc


# for CNN we'll use audio mono (1).
num_channels = 1


# OSC parameters
ip = "127.0.0.1"
osc_client_port = 9001
osc_server_port = 9063



################################ starting the server #######################################


fc.OSC_server(n_mfcc, max_pad_len, num_channels, ip, osc_server_port, osc_client_port)





