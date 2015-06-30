//
//  Copyright (c) 2015 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MovieTableViewController.h"
#import "MovieRecord.h"
#import "ASAPIClient.h"
#import "UIImageView+AFNetworking.h"
#import "MoviesSearch-Swift.h"

@interface MovieTableViewController ()

@property (nonatomic) UISearchController *searchController;

@property (nonatomic) ASRemoteIndex *movieIndex;
@property (nonatomic) ASQuery *query;

@property (nonatomic) NSMutableArray *movies;

@property (nonatomic) NSNumber *searchId;
@property (nonatomic) NSNumber *displayedSearchId;
@property (nonatomic) NSNumber *loadedPage;
@property (nonatomic) NSNumber *nbPages;

@property (nonatomic) UIImage *placeholder;

@end

@implementation MovieTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    
    // Add the search bar
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
    
    // Algolia Search
    ASAPIClient *apiClient = [ASAPIClient apiClientWithApplicationID:@"latency" apiKey:@"dce4286c2833e8cf4b7b1f2d3fa1dbcb"];
    self.movieIndex = [apiClient getIndex:@"movies"];
    
    self.query = [[ASQuery alloc] init];
    self.query.attributesToRetrieve = @[@"title", @"image", @"rating", @"year"];
    self.query.attributesToHighlight = @[@"title"];
    
    self.movies = [NSMutableArray array];
    self.searchId = 0;
    self.displayedSearchId = [NSNumber numberWithInt:-1];
    self.loadedPage = 0;
    self.nbPages = 0;
    
    self.placeholder = [UIImage imageNamed:@"white"];
    
    
    // First load
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.movies count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"movieCell" forIndexPath:indexPath];
    
    if (indexPath.row + 5 >= [self.movies count]) {
        [self loadMore];
    }
    
    MovieRecord *movie = self.movies[indexPath.row];
    cell.textLabel.highlightedTextColor = [UIColor colorWithRed:1 green:1 blue:0.898 alpha:1];
    cell.textLabel.highlightedText = movie.title;
    //cell.textLabel.text = movie.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", movie.year];
    
    // Avoid loading image that we don't need anymore
    [cell.imageView cancelImageRequestOperation];
    // Load the image and display another image during the loading
    [cell.imageView setImageWithURL:[NSURL URLWithString:movie.image] placeholderImage:self.placeholder];
    
    return cell;
}

#pragma mark - Search bar

-(void) updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.query.fullTextQuery = self.searchController.searchBar.text;
    int curSearchId = [self.searchId intValue];
    
    [self.movieIndex search:self.query success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
        if (curSearchId <= [self.displayedSearchId intValue]) {
            return; // Newest query already displayed
        }
        
        self.displayedSearchId = [NSNumber numberWithInt:curSearchId];
        self.loadedPage = 0; // Reset loaded page
        
        // Decode JSON
        NSArray *hits = result[@"hits"];
        self.nbPages = result[@"nbPages"];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (int i = 0; i < [hits count]; ++i) {
            [tmp addObject:[[MovieRecord alloc] init:hits[i]]];
        }
        
        // Reload view with the new data
        [self.movies removeAllObjects];
        [self.movies addObjectsFromArray:tmp];
        [self.tableView reloadData];
    } failure:nil];
    
    self.searchId = [NSNumber numberWithInt:[self.searchId intValue] + 1];
}

#pragma mark - Load more

-(void) loadMore {
    if ([self.loadedPage intValue] + 1 >= [self.nbPages intValue]) {
        return; // All pages already loaded
    }
    
    ASQuery *nextQuery = [self.query copy];
    nextQuery.page = [self.loadedPage intValue] + 1;
    
    [self.movieIndex search:nextQuery success:^(ASRemoteIndex *index, ASQuery *query, NSDictionary *result) {
        if (![nextQuery.fullTextQuery isEqualToString:self.query.fullTextQuery]) {
            return; // Query has changed
        }
        
        self.loadedPage = [NSNumber numberWithUnsignedInteger:nextQuery.page];
        NSArray *hits = result[@"hits"];
        
        NSMutableArray *tmp = [NSMutableArray array];
        for (int i = 0; i < [hits count]; ++i) {
            [tmp addObject:[[MovieRecord alloc] init:hits[i]]];
        }
        
        // Reload view with the loaded data
        [self.movies addObjectsFromArray:tmp];
        [self.tableView reloadData];
    } failure:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
