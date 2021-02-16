local _, addonTable = ...;
local StdUi = LibStub('StdUi');

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Monk = addonTable.Monk;

local defaultOptions = {
	alwaysGlowCooldowns = true,
	XuenAsCooldown = true,
	ToDAsCooldown = true,
	WeaponsOfOrderAsCooldown = true,
	StormEarthAndFireAsCooldown = true,
	TouchOfKarmaAsCooldown = true,
	AnyAsCooldown = false,
};

function Monk:GetConfig()
	local config = {
		layoutConfig = { padding = { top = 30 } },
		database     = self.db,
		rows         = {
			[1] = {
				monk = {
					type = 'header',
					label = 'Monk options'
				}
			},
			[2] = {
				AnyAsCooldown = {
					type   = 'checkbox',
					label  = 'Use all spells',
					column = 12
				},
			},
			[3] = {
				XuenAsCooldown = {
					type   = 'checkbox',
					label  = 'Invoke Xuen the White Tiger as cooldown',
					column = 12
				},
			},
			[4] = {
				ToDAsCooldown = {
					type   = 'checkbox',
					label  = 'Touch of Death as cooldown',
					column = 12
				},
			},
			[5] = {
				CovenantAsCooldown = {
					type   = 'checkbox',
					label  = 'Covenant ability as cooldown',
					column = 12
				},
			},
			[6] = {
				StormEarthAndFireAsCooldown = {
					type   = 'checkbox',
					label  = 'Storm Earth and Fire as cooldown',
					column = 12
				},
			},
			[7] = {
				TouchOfKarmaAsCooldown = {
					type   = 'checkbox',
					label  = 'Touch of Karma as cooldown',
					column = 12
				},
			},
			[11] = {
				advanced = {
					type = 'header',
					label = 'Advanced options'
				}
			},
			[12] = {
				alwaysGlowCooldowns = {
					type = 'checkbox',
					label = 'Always glow "X as Cooldown" abilities'
				}
			},
			[13] = {
				infoText = {
					type  = 'label',
					label = 'LEAVE THIS CHECKED UNLESS YOU\'VE READ AND UNDERSTOOD THIS DISCLAIMER! ' ..
						'There are some abilities that have a set place in your rotation, but you may ' ..
						'still want to use as if they were cooldowns.  You can accomplish this ' ..
						'using the "X as Cooldown" options on this page. In that case, you likely ' ..
						'want the abilities to always be highlighted as available when off cooldown. ' ..
						'By unchecking the above option, you\'re choosing to ONLY glow these cooldowns ' ..
						'in situations where they\'d normally be suggested as part of your rotation. ' ..
						'This means that, for abilities that require setup (such as pooling Runic ' ..
						'Power for Summon Gargoyle), the cooldown will only be highlighted once ' ..
						'you\'ve manually met the requirements, and MaxDps might not suggest actions ' ..
						'that build toward those requirements. If you don\'t want to ignore MaxDps ' ..
						'to manually set up your cooldowns, leave the above checkbox checked.'
				},
			},
		},
	};

	return config;
end


function Monk:InitializeDatabase()
	if self.db then return end;

	if not MaxDpsMonkOptions then
		MaxDpsMonkOptions = defaultOptions;
	end

	for k, v in pairs(defaultOptions) do
		if MaxDpsMonkOptions[k] == nil then
			MaxDpsMonkOptions[k] = v;
		end
	end

	self.db = MaxDpsMonkOptions;
end

function Monk:CreateConfig()
	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(nil, 100, 100, 'Monk Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = 'Monk';
	optionsFrame.parent = 'MaxDps';

	StdUi:BuildWindow(self.optionsFrame, self:GetConfig());

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });

	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
	InterfaceCategoryList_Update();
	InterfaceOptionsOptionsFrame_RefreshCategories();
	InterfaceAddOnsList_Update();
end
