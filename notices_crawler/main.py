#################################################################################
################################ Web Crawler ####################################
#                                                                               #
#  1 - create a spider                                                          #
#  2 - search all notices based on variable start_urls                          #
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


#################################### setting variables ##########################################

# set delay time
delay_time = 50

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
																		
																		# add notice information to notices
																		notices.append ( [ item.css(NAME_SELECTOR).extract_first(), item.css(LINK_SELECTOR).extract_first() ] )


          print(notices)

          # save notices informations in directory
          notices_df = pd.DataFrame(notices, columns=['name','url'])
          notices_df.to_pickle('./data_saved/notices_url')

          df = pd.read_pickle('./data_saved/notices_url')
          print(df)

          print('\n\nData updated sucessfull! (',time.strftime("%c"),')')

          print("\nWaiting for next update...")

          time.sleep(delay_time)



