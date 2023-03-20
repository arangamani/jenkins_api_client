# encoding: UTF-8
require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::User do
  context "With properly initialized Client" do
    ADMIN_CONFIGURE_TEXT = <<__ADMIN_CONFIGURE
<!DOCTYPE html><html><head resURL="/static/70901acb" data-rooturl="" data-resurl="/static/70901acb">
    <title>User ‘admin’ Configuration [Jenkins]</title>
    <link rel="stylesheet" href="/static/70901acb/css/layout-common.css" type="text/css" />
    <link rel="stylesheet" href="/static/70901acb/css/style.css" type="text/css" />
    <input name="_.fullName" type="text" class="setting-input   " value="admin" />/td></tr><tr><td class="setting-leftspace"> </td><td class="setting-name">Description</td><td class="setting-main"><textarea name="_.description" rows="5" class="setting-input   "></textarea><div class="textarea-handle"></div></td><td class="setting-help"><a helpURL="/help/user/description.html" href="#" class="help-button"><img src="/static/70901acb/images/16x16/help.png" alt="Help for feature: Description" style="width: 16px; height: 16px; " class="icon-help icon-sm" /></a></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr class="help-area"><td></td><td colspan="2"><div class="help">Loading...</div></td><td></td></tr><link rel='stylesheet' href='/adjuncts/70901acb/lib/form/section_.css' type='text/css' /><script src='/adjuncts/70901acb/lib/form/section_.js' type='text/javascript'></script><tr name="userProperty0" style="display:none" class="row-set-start row-group-start"></tr><tr class="row-set-end row-group-end"></tr><tr><td colspan="4"><div class="section-header">API Token</div></td></tr><tr name="userProperty1" style="display:none" class="row-set-start row-group-start"></tr><tr><td></td><td></td><td><script src='/adjuncts/70901acb/lib/form/advanced/advanced.js' type='text/javascript'></script><div style="text-align:left" class="advancedLink"><span style="display: none" id="id245"><img src="/static/70901acb/images/24x24/notepad.png" tooltip="One or more fields in this block have been edited." style="width: 24px; height: 24px; vertical-align: baseline" class="icon-notepad icon-md" /></span> <input type="button" value="Show API Token..." class="advanced-button advancedButton" /></div><table class="advancedBody"><tbody><tr><td class="setting-leftspace"> </td><td class="setting-name">User ID</td><td class="setting-main"><input readonly="readonly" name="_." type="text" class="setting-input  " value="admin" /></td><td class="setting-no-help"></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr><td class="setting-leftspace"> </td><td class="setting-name">API Token</td><td class="setting-main"><input readonly="readonly" name="_.apiToken" id="apiToken" type="text" class="setting-input  " value="12345678" /></td><td class="setting-help"><a helpURL="/descriptor/jenkins.security.ApiTokenProperty/help/apiToken" href="#" class="help-button"><img src="/static/70901acb/images/16x16/help.png" alt="Help for feature: API Token" style="width: 16px; height: 16px; " class="icon-help icon-sm" /></a></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr class="help-area"><td></td><td colspan="2"><div class="help">Loading...</div></td><td></td></tr><tr><td class="setting-leftspace"> </td><td class="setting-name"></td><td class="setting-main"><div style="float:right"><input onclick="validateButton('/user/admin/descriptorByName/jenkins.security.ApiTokenProperty/changeToken','',this)" type="button" value="Change API Token" class="yui-button validate-button" /></div><div style="display:none;"><img src="/static/70901acb/images/spinner.gif" />
  <input name="email.address" type="text" class="setting-input   " value="" /></td><td class="setting-no-help"></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr><td colspan="2"></td><td class="setting-description">Your e-mail address, like <tt>joe.chin@sun.com</tt></td><td></td></tr><tr class="row-set-end row-group-end"></tr><tr><td colspan="4"><div class="section-header">My Views</div></td></tr><tr name="userProperty4" style="display:none" class="row-set-start row-group-start"></tr><tr><td class="setting-leftspace"> </td><td class="setting-name">Default View</td><td class="setting-main">
  <input checkUrl="'/user/admin/my-views/viewExistsCheck?value='+encodeURIComponent(this.value)+'&amp;exists=true'" name="_.primaryViewName" type="text" class="setting-input validated  " value="" /></td><td class="setting-no-help"></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr><td colspan="2"></td><td class="setting-description">The view selected by default when navigating to the users private views</td><td></td></tr><tr class="row-set-end row-group-end"></tr><tr><td colspan="4"><div class="section-header">SSH Public Keys</div></td></tr><tr name="userProperty7" style="display:none" class="row-set-start row-group-start"></tr><tr><td class="setting-leftspace"> </td><td class="setting-name">SSH Public Keys</td><td class="setting-main"><textarea name="_.authorizedKeys" rows="5" class="setting-input   "></textarea><div class="textarea-handle"></div></td><td class="setting-help"><a helpURL="/descriptor/org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl/help/authorizedKeys" href="#" class="help-button"><img src="/static/70901acb/images/16x16/help.png" alt="Help for feature: SSH Public Keys" style="width: 16px; height: 16px; " class="icon-help icon-sm" /></a></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr class="help-area"><td></td><td colspan="2"><div class="help">Loading...</div></td><td></td></tr><tr class="row-set-end row-group-end"></tr><tr><td colspan="4"><div class="section-header">Setting for search</div></td></tr><tr name="userProperty8" style="display:none" class="row-set-start row-group-start"></tr><tr><td class="setting-leftspace"> </td><td class="setting-name">Case-sensitivity</td><td class="setting-main"><input name="insensitiveSearch" type="checkbox" class="  " /><label class="attach-previous">Insensitive search tool</label></td><td class="setting-no-help"></td></tr><tr class="validation-error-area"><td colspan="2"></td><td></td><td></td></tr><tr class="row-set-end row-group-end"></tr><tr><td colspan="4"><div id="bottom-sticker"><div class="bottom-sticker-inner"><input name="Submit" type="submit" value="Save" class="submit-button primary" /><script src='/adjuncts/70901acb/lib/form/apply/apply.js' type='text/javascript'></script><input type="hidden" name="core:apply" value="" /><input name="Apply" type="button" value="Apply" class="apply-button applyButton" /></div></div></td></tr></table></form><script src='/adjuncts/70901acb/lib/form/confirm.js' type='text/javascript'></script></div></div><footer><div class="container-fluid"><div class="row"><div class="col-md-6" id="footer"></div><div class="col-md-18"><span class="page_generated">Page generated: Sep 10, 2016 12:54:41 AM UTC</span><span class="rest_api"><a href="api/">REST API</a></span><span class="jenkins_ver"><a href="http://jenkins-ci.org/">Jenkins ver. 2.7.4</a></span></div></div></div></footer></body></html>
__ADMIN_CONFIGURE

    FRED_TXT = <<__FRED
{
  "absoluteUrl" : "https://myjenkins.example.com/jenkins/user/fred",
  "description" : "",
  "fullName" : "Fred Flintstone",
  "id" : "fred",
  "property" : [
    {
    },
    {
    },
    {
      "address" : "fred@slaterockandgravel.com"
    },
    {
    },
    {
    },
    {
      "insensitiveSearch" : false
    }
  ]
}
__FRED

    WILMA_TXT = <<__WILMA
{
  "absoluteUrl" : "https://myjenkins.example.com/jenkins/user/wilma",
  "description" : "",
  "fullName" : "wilma",
  "id" : "wilma",
  "property" : [
    {
    },
    {
    },
    {
    },
    {
    },
    {
    },
    {
    }
  ]
}
__WILMA

    FRED_JSON = JSON.parse(FRED_TXT)
    WILMA_JSON = JSON.parse(WILMA_TXT)
    PEOPLE_JSON = JSON.parse(<<__PEEPS
{
  "users" : [
    {
      "lastChange" : 1375293464494,
      "project" : {
        "name" : "a project",
        "url" : "a url to a project"
      },
      "user" : {
        "absoluteUrl" : "a url to a user",
        "fullName" : "Fred Flintstone"
      }
    }
  ]
}
__PEEPS
)

    USERLIST_JSON = JSON.parse(<<__USERLIST
{
  "fred": #{FRED_TXT}
}
__USERLIST
)

    before do
      mock_logger = Logger.new "/dev/null"
      mock_timeout = 300
      @client = double
      expect(@client).to receive(:logger).and_return(mock_logger)
      expect(@client).to receive(:timeout).and_return(mock_timeout)
      @client.stub(:api_get_request).with('/asynchPeople').and_return(PEOPLE_JSON)
      @client.stub(:api_get_request).with('/user/Fred%20Flintstone').and_return(FRED_JSON)
      @client.stub(:api_get_request).with('/user/fred').and_return(FRED_JSON)
      @client.stub(:api_get_request).with('/user/wilma').and_return(WILMA_JSON)
      @client.stub(:api_get_request).with('/user/admin/configure', nil, '').and_return(ADMIN_CONFIGURE_TEXT)
      @user = JenkinsApi::Client::User.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          mock_timeout = 300
          expect(@client).to receive(:logger).and_return(mock_logger)
          expect(@client).to receive(:timeout).and_return(mock_timeout)
          expect { JenkinsApi::Client::User.new(@client) } .not_to raise_error
        end
      end

      describe "#list" do
        it "sends a request to list the users" do
          @user.list.should eq(USERLIST_JSON)
        end
      end

      describe "#get" do
        it "returns dummy user if user cannot be found" do
          # This is artifact of Jenkins - It'll create a user to match the name you give it - even on a fetch
          @user.get("wilma").should eq(WILMA_JSON)
        end

        it "returns valid user if user can be found" do
          @user.get("fred").should eq(FRED_JSON)
        end
      end

      describe "#get_api_token" do
        it "returns the user's API token" do
          @user.get_api_token('admin').should eq('12345678')
        end
      end

    end
  end
end
