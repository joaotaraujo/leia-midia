#################################################################################
################################ Web Crawler ####################################
#                                                                               #
#  1 - create a spider                                                          #
#  2 - search all notices based on variable start_urls                          #
#  3 - save notices information into notices_info.json file                     #
#  4 - update notices based on delay_time                                       #
#                                                                               #
#  OBS: to run type: scrapy runspider main.py                                   #
#                                                                               #
#  Author: João Teixeira Araújo                                                 #
#                                                                               #
#################################################################################


######################################### imports ###############################################

# for crawler
import scrapy

# to save data
import pandas as pd

# to set delay_time of update
import time

from keras.models import model_from_json
import pandas as pd	
import numpy as np

# to extract notices information 
from newsplease import NewsPlease

#################################### setting variables ##########################################

# set delay time
delay_time = 10000

# set starts_url
url = 'https://g1.globo.com/politica'


#################################### main function ##########################################

# create the spider to get url information
class NoticesSpider_urls(scrapy.Spider):

    name = "notices_spider"
    start_urls = [url]

				# here is the logic of the spider
    def parse(self, response):

								# pick the element with "_label_event" name
        SET_SELECTOR = '._label_event'


        while(1):

          notices = []

										# for each element in selector
          for item in response.css(SET_SELECTOR):

														# pick text and the link of the <a> html element
              NAME_SELECTOR = 'a ::text'
              LINK_SELECTOR = 'a ::attr(href)'

														# some links and text's are with None value
													 # here we dont get them
              if ( str(item.css(NAME_SELECTOR).extract_first()) != 'None'):
																		
                  print("\nGot URL: ", item.css(LINK_SELECTOR).extract_first());


                  notice = NewsPlease.from_url(item.css(LINK_SELECTOR).extract_first())

														    # put all notice information in list
                  notices.append([notice.title, notice.description, notice.authors, notice.date_publish, notice.image_url, notice.maintext])

                  print("\nGot notice: ", notice.title)

      
          # save notices information into a json file
          notices_df = pd.DataFrame(notices, columns=['title', 'description', 'authors', 'date_publish', 'image_url', 'maintext'])
          notices_df.to_json (r'./data_saved/notices_info.json')


          #update_notice_information();

          print('\n\nData updated sucessfull! (',time.strftime("%c"),')')

          print("\nWaiting for next update...")

          time.sleep(delay_time)



