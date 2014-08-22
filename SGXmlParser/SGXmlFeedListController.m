//
//  SGXmlFeedListController.m
//  SGXmlParser
//
//  Created by Sourav on 20/08/14.
//  Copyright (c) 2014 Sourav. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "SGXmlFeedListController.h"
#import "SGXmlElement.h"
#import "SGXmlFeedDetailController.h"
#import "SGHelper.h"

#define FeedURL @"http://rss.nytimes.com/services/xml/rss/nyt/Multimedia.xml"



@interface SGXmlFeedListController ()<NSXMLParserDelegate>{
    IBOutlet UITableView *feedTableView;
}

@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, strong) SGXmlElement *rootElement;
@property (nonatomic, strong) SGXmlElement *currentElementPointer;
@property (nonatomic, strong) NSMutableArray *titleArray;
@property (nonatomic, strong) NSMutableArray *linkArray;
@property (strong,nonatomic)UIActivityIndicatorView *spinner;


@end

@implementation SGXmlFeedListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Feed";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    
    if ([SGHelper networkReachable]) {
        [self getXmlData];
    }else{
        [self showNetworkAlert];
    }
    
}

-(void)showNetworkAlert{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Network" message:@"Please connect to the internet to get the latest feeds" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

-(void)getXmlData{
    
    
    _spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = self.view.center;
    [self.view addSubview:_spinner];
    [_spinner startAnimating];
    
    
    NSURL *url = [NSURL URLWithString:FeedURL];
    NSData *xml = [[NSData alloc] initWithContentsOfURL:url];
    
    self.xmlParser = [[NSXMLParser alloc] initWithData:xml];
    self.xmlParser.delegate = self;
    if ([self.xmlParser parse]){
        
        /* This is the part where you need to change. Accodring to your XML */
        
        
        /* self.rootElement is now the root element in the XML */
        SGXmlElement *channelElement = self.rootElement.subElements[0];
        
        int chanelSubElementsCount = (int)[channelElement.subElements count];
        
        self.titleArray = [[NSMutableArray alloc] initWithCapacity:chanelSubElementsCount-10];
        self.linkArray = [[NSMutableArray alloc] initWithCapacity:chanelSubElementsCount-10];
        
        for (int i=10; i<chanelSubElementsCount; i++) {
            
            SGXmlElement *itemElement = channelElement.subElements[i];
            //NSLog(@"%@ %d", itemElement.name,i);
            SGXmlElement *titleElement = itemElement.subElements[1];
            [self.titleArray addObject:[titleElement text]];
            
            SGXmlElement *descriptionElement = itemElement.subElements[2];
            [self.linkArray addObject:[descriptionElement text]];
            
        }
        
        /* End This is the part where you need to change. Accodring to your XML */

        
        [_spinner stopAnimating];
        [feedTableView reloadData];
        
        
    } else{
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error !!" message:@"Some error in parsing the data. Please try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        
    }
    
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    self.rootElement = nil;
    self.currentElementPointer = nil;
}

- (void)        parser:(NSXMLParser *)parser
       didStartElement:(NSString *)elementName
          namespaceURI:(NSString *)namespaceURI
         qualifiedName:(NSString *)qName
            attributes:(NSDictionary *)attributeDict{
    
    if (self.rootElement == nil){
        /* We don't have a root element. Create it and point to it */
        self.rootElement = [[SGXmlElement alloc] init];
        self.currentElementPointer = self.rootElement;
    } else {
        /* Already have root. Create new element and add it as one of
         the subelements of the current element */
        SGXmlElement *newElement = [[SGXmlElement alloc] init];
        newElement.parent = self.currentElementPointer;
        [self.currentElementPointer.subElements addObject:newElement];
        self.currentElementPointer = newElement;
    }
    
    self.currentElementPointer.name = elementName;
    self.currentElementPointer.attributes = attributeDict;
    
}

- (void)        parser:(NSXMLParser *)parser
       foundCharacters:(NSString *)string{
    
    if ([self.currentElementPointer.text length] > 0){
        self.currentElementPointer.text =
        [self.currentElementPointer.text stringByAppendingString:string];
    } else {
        self.currentElementPointer.text = string;
    }
    
}

- (void)        parser:(NSXMLParser *)parser
         didEndElement:(NSString *)elementName
          namespaceURI:(NSString *)namespaceURI
         qualifiedName:(NSString *)qName{
    
    self.currentElementPointer = self.currentElementPointer.parent;
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
    self.currentElementPointer = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.titleArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell"];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    NSString *titleText = [self.titleArray objectAtIndex:indexPath.row];
    NSAttributedString *attributedTitleText = [SGHelper attributedString:titleText alignment:NSTextAlignmentLeft];
    CGFloat screenWidth = self.view.frame.size.width;

    CGFloat descHeight = [SGHelper findHeightForAttributedText:attributedTitleText havingWidth:screenWidth-20 andFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    titleLabel.frame = CGRectMake(10, 10, screenWidth-20, descHeight);
    titleLabel.attributedText = attributedTitleText;
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0;
    
    NSString *titleText = [self.titleArray objectAtIndex:indexPath.row];
    NSAttributedString *attributedTitleText = [SGHelper attributedString:titleText alignment:NSTextAlignmentLeft];
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat descHeight = [SGHelper findHeightForAttributedText:attributedTitleText havingWidth:screenWidth-20 andFont:[UIFont fontWithName:@"HelveticaNeue" size:18.0]];
    
    height = descHeight + 20;
    
    return height;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    SGXmlFeedDetailController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SGXmlFeedDetailController"];
    controller.url = [self.linkArray objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
    
}

@end
